require "thread"

# Since we call to_s on new_connection_args and use that as a hash
# We need to make sure the memory address of the object is not used as part of the key
# Otherwise identical objects with different memory address won't get a hash hit.
# In the case of proxy commands, this can lead to proxy processes leaking
# And in severe cases can cause deploys to fail due to default file descriptor limits
# An alternate solution would be to use a different means of generating hash keys
module Net; module SSH; module Proxy
  class Command
    def inspect
      @command_line_template
    end
  end
end;end;end

module SSHKit

  module Backend

    class ConnectionPool

      attr_accessor :idle_timeout

      def initialize
        self.idle_timeout = 30
        @mutex = Mutex.new
        @pool = {}
      end

      def checkout(*new_connection_args, &block)
        entry = nil
        key = new_connection_args.to_s
        if idle_timeout
          prune_expired
          entry = find_live_entry(key)
        end
        entry || create_new_entry(new_connection_args, key, &block)
      end

      def checkin(entry)
        if idle_timeout
          prune_expired
          entry.expires_at = Time.now + idle_timeout
          @mutex.synchronize do
            @pool[entry.key] ||= []
            @pool[entry.key] << entry
          end
        end
      end

      def close_connections
        @mutex.synchronize do
          @pool.values.flatten.map(&:connection).uniq.each do |conn|
            if conn.respond_to?(:closed?) && conn.respond_to?(:close)
              conn.close unless conn.closed?
            end
          end
          @pool.clear
        end
      end

      def flush_connections
        @mutex.synchronize { @pool.clear }
      end

      private

      def prune_expired
        @mutex.synchronize do
          @pool.each_value do |entries|
            entries.collect! do |entry|
              if entry.expired?
                entry.close unless entry.closed?
                nil
              else
                entry
              end
            end.compact!
          end
        end
      end

      def find_live_entry(key)
        @mutex.synchronize do
          return nil unless @pool.key?(key)
          while (entry = @pool[key].shift)
            return entry if entry.live?
          end
        end
        nil
      end

      def create_new_entry(args, key, &block)
        Entry.new block.call(*args), key
      end

      Entry = Struct.new(:connection, :key) do
        attr_accessor :expires_at

        def live?
          !expired? && !closed?
        end

        def expired?
          expires_at && Time.now > expires_at
        end

        def close
          connection.respond_to?(:close) && connection.close
        end

        def closed?
          connection.respond_to?(:closed?) && connection.closed?
        end
      end

    end
  end
end
