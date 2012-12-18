require 'timeout'

module Deploy

  NoValidHosts = Class.new(StandardError)
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

    attr_accessor :hosts, :connections

    def initialize(raw_hosts)
      @raw_hosts = Array(raw_hosts)
      raise NoValidHosts unless Array(raw_hosts).any?
      resolve_hosts!
      connect_hosts!
    end

    def each(&block)
      hosts.each do |host|
        yield host, connections[host.to_key]
      end
    end

    private

      def connect_hosts!
        Timeout.timeout self.class.connection_timeout, ConnectionTimeoutExpired do
          @connections = [].tap do |threads|
            @hosts.each do |h|
              threads << Thread.new do
                Thread.current[:host] = h
                Thread.current[:connection] = self.class.backend.connect(h)
              end
            end
          end.map(&:join).inject({}) { |h, thread| h[thread[:host].to_key] = thread[:connection]; h }
        end
      end

      def resolve_hosts!
        @hosts = @raw_hosts.collect { |rh| Host.new(rh) }.uniq
      end

  end

end
