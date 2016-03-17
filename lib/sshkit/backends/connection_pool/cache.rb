# A Cache holds connections for a given key. Each connection is stored along
# with an expiration time so that its idle duration can be measured.
class SSHKit::Backend::ConnectionPool::Cache
  def initialize(idle_timeout, closer)
    @connections = []
    @connections.extend(MonitorMixin)
    @idle_timeout = idle_timeout
    @closer = closer
  end

  # Remove and return a fresh connection from this Cache. Returns `nil` if
  # the Cache is empty or if all existing connections have gone stale.
  def pop
    connections.synchronize do
      evict
      _, connection = connections.pop
      connection
    end
  end

  # Return a connection to this Cache.
  def push(conn)
    # No need to cache if the connection has already been closed.
    return if closed?(conn)

    connections.synchronize do
      connections.push([Time.now + idle_timeout, conn])
    end
  end

  # Close and remove any connections in this Cache that have been idle for
  # too long.
  def evict
    # Peek at the first connection to see if it is still fresh. If so, we can
    # return right away without needing to use `synchronize`.
    first_expires_at, _connection = connections.first
    return if first_expires_at.nil? || fresh?(first_expires_at)

    connections.synchronize do
      fresh, stale = connections.partition do |expires_at, _|
        fresh?(expires_at)
      end
      connections.replace(fresh)
      stale.each { |_, conn| closer.call(conn) }
    end
  end

  # Close all connections and completely clear the cache.
  def clear
    connections.synchronize do
      connections.map(&:last).each(&closer)
      connections.clear
    end
  end

  protected

  attr_reader :connections, :idle_timeout, :closer

  private

  def fresh?(expires_at)
    expires_at > Time.now
  end

  def closed?(conn)
    conn.respond_to?(:closed?) && conn.closed?
  end
end
