require "monitor"

module SSHKit

  module Backend

    class ConnectionPool

      attr_accessor :idle_timeout

      def initialize
        self.idle_timeout = 30
        @monitor = Monitor.new
        @connections = {}
      end

      def create_or_reuse_connection(*new_connection_args, &block)
        # Optimization: completely bypass the pool if idle_timeout is zero.
        return yield(*new_connection_args) if idle_timeout == 0
        entry=nil
        @monitor.synchronize do
          key = new_connection_args.to_s
          entry = find_and_reject_invalid(key) { |e| e.expired? || e.closed? }

          if entry.nil?
            entry = store_entry(key, yield(*new_connection_args))
          end

          entry.expires_at = Time.now + idle_timeout if idle_timeout
          entry.connection
        end
      end

      private

      def connections
         @connections
      end

      def find_and_reject_invalid(key, &block)
        entry = connections[key]
        invalid = entry && yield(entry)

        connections.delete(entry) if invalid

        invalid ? nil : entry
      end

      def store_entry(key, connection)
        connections[key] = Entry.new(connection)
      end


      Entry = Struct.new(:connection) do
        attr_accessor :expires_at

        def expired?
          expires_at && Time.now > expires_at
        end

        def closed?
          connection.respond_to?(:closed?) && connection.closed?
        end
      end

    end

  end
end
