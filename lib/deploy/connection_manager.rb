require 'timeout'

module Deploy

  ConnectionTimeoutExpired = Class.new(StandardError)

  class ConnectionManager

    class << self
      attr_writer :backend, :connection_timeout
      def backend
        (@backend.class == Class) ? @backend.new : @backend
      end
      def connection_timeout
        @connection_timeout ||= 5
      end
    end

    attr_accessor :hosts

    def initialize(raw_hosts)
      @raw_hosts = Array(raw_hosts)
      resolve_hosts!
      connect_hosts!
    end

    private

      def connect_hosts!
        Timeout.timeout self.class.connection_timeout, ConnectionTimeoutExpired do
          @connections = [].tap do |threads|
            @hosts.each do |h|
              threads << Thread.new do
                Thread.current[:connection] = self.class.backend.connect(h)
              end
            end
          end.map(&:join).collect { |t| t[:connection] }
        end
      end

      def resolve_hosts!
        @hosts = @raw_hosts.collect { |rh| Host.new(rh) }.uniq
      end

  end

end
