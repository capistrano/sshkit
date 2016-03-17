require "monitor"
require "thread"

# Since we call to_s on new connection arguments and use that as a cache key, we
# need to make sure the memory address of the object is not used as part of the
# key. Otherwise identical objects with different memory address won't reuse the
# cache.
#
# In the case of proxy commands, this can lead to proxy processes leaking, and
# in severe cases can cause deploys to fail due to default file descriptor
# limits. An alternate solution would be to use a different means of generating
# hash keys.
#
require "net/ssh/proxy/command"
class Net::SSH::Proxy::Command
  # Ensure a stable string value is used, rather than memory address.
  def inspect
    @command_line_template
  end
end

# The ConnectionPool caches connections and allows them to be reused, so long as
# the reuse happens within the `idle_timeout` period. Timed out connections are
# closed, forcing a new connection to be used in that case.
#
# Additionally, a background thread is started to check for abandoned
# connections that have timed out without any attempt at being reused. These
# are eventually closed as well and removed from the cache.
#
# If `idle_timeout` set to `false`, `0`, or `nil`, no caching is performed, and
# a new connection is created and then immediately closed each time. The default
# timeout is 30 (seconds).
#
# There is a single public method: `with`. Example usage:
#
#   pool = SSHKit::Backend::ConnectionPool.new
#   pool.with(Net::SSH.method(:start), "host", "username") do |connection|
#     # do stuff with connection
#   end
#
class SSHKit::Backend::ConnectionPool
  attr_accessor :idle_timeout

  def initialize(idle_timeout=30)
    @idle_timeout = idle_timeout
    @caches = {}
    @caches.extend(MonitorMixin)
    @timed_out_connections = Queue.new
    Thread.new { run_eviction_loop }
  end

  # Creates a new connection or reuses a cached connection (if possible) and
  # yields the connection to the given block. Connections are created by
  # invoking the `connection_factory` proc with the given `args`. The arguments
  # are used to construct a key used for caching.
  def with(connection_factory, *args)
    cache = find_cache(args)
    conn = cache.pop || begin
      connection_factory.call(*args)
    end
    yield(conn)
  ensure
    cache.push(conn) unless conn.nil?
  end

  # Immediately remove all cached connections, without closing them. This only
  # exists for unit test purposes.
  def flush_connections
    caches.synchronize { caches.clear }
  end

  # Immediately close all cached connections and empty the pool.
  def close_connections
    caches.synchronize do
      caches.values.each(&:clear)
      caches.clear
      process_deferred_close
    end
  end

  protected

  attr_reader :caches, :timed_out_connections

  private

  def cache_enabled?
    idle_timeout && idle_timeout > 0
  end

  # Look up a Cache that matches the given connection arguments.
  def find_cache(args)
    if cache_enabled?
      key = args.to_s
      caches[key] || thread_safe_find_or_create_cache(key)
    else
      NilCache.new(method(:silently_close_connection))
    end
  end

  # Cache creation needs to happen in a mutex, because otherwise a race
  # condition might cause two identical caches to be created for the same key.
  def thread_safe_find_or_create_cache(key)
    caches.synchronize do
      caches[key] ||= begin
        Cache.new(idle_timeout, method(:silently_close_connection_later))
      end
    end
  end

  # Loops indefinitely to close connections and to find abandoned connections
  # that need to be closed.
  def run_eviction_loop
    loop do
      process_deferred_close

      # Periodically sweep all Caches to evict stale connections
      sleep([idle_timeout, 5].min)
      caches.values.each(&:evict)
    end
  end

  # Immediately close any connections that are pending closure.
  # rubocop:disable Lint/HandleExceptions
  def process_deferred_close
    until timed_out_connections.empty?
      connection = timed_out_connections.pop(true)
      silently_close_connection(connection)
    end
  rescue ThreadError
    # Queue#pop(true) raises ThreadError if the queue is empty.
    # This could only happen if `close_connections` is called at the same time
    # the background eviction thread has woken up to close connections. In any
    # case, it is not something we need to care about, since an empty queue is
    # perfectly OK.
  end
  # rubocop:enable Lint/HandleExceptions

  # Adds the connection to a queue that is processed asynchronously by a
  # background thread. The connection will eventually be closed.
  def silently_close_connection_later(connection)
    timed_out_connections << connection
  end

  # Close the given `connection` immediately, assuming it responds to a `close`
  # method. If it doesn't, or if `nil` is provided, it is silently ignored. Any
  # `StandardError` is also silently ignored. Returns `true` if the connection
  # was closed; `false` if it was already closed or could not be closed due to
  # an error.
  def silently_close_connection(connection)
    return false unless connection.respond_to?(:close)
    return false if connection.respond_to?(:closed?) && connection.closed?
    connection.close
    true
  rescue StandardError
    false
  end
end

require "sshkit/backends/connection_pool/cache"
require "sshkit/backends/connection_pool/nil_cache"
