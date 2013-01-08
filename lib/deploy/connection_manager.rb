require 'timeout'

class Runner

  attr_reader :hosts, :connections, :block

  def initialize(hosts, connections, &block)
    @hosts       = Array(hosts)
    @connections = connections
    @block       = block
  end

end

class ParallelRunner < Runner
  def run
    threads = []
    hosts.each do |host|
      threads << Thread.new(host, connections[host.to_key]) { |h,c| block.call h, c }
    end
    threads.map(&:join)
  end
end

class SequentialRunner < Runner
  attr_writer :wait_interval
  def run
    hosts.each do |host|
      block.call host, connections[host.to_key]
      sleep wait_interval
    end
  end
  private
  def wait_interval
    @wait_interval ||= 2
  end
end

class GroupRunner < SequentialRunner
  attr_writer :group_size
  def run
    hosts.each_slice(group_size).collect do |group_hosts|
      ParallelRunner.new(group_hosts, connections, &block).run
      sleep wait_interval
    end.flatten
  end
  private
  def group_size
    @group_size ||= 2
  end
end

module Deploy

  NoValidHosts = Class.new(StandardError)
  ConnectionTimeoutExpired = Class.new(StandardError)

  class ConnectionManager

    class << self

      attr_writer :connection_timeout

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

    def each(options=default_options, &block)
      case options[:in]
      when :parallel then ParallelRunner
      when :sequence then SequentialRunner
      when :groups   then GroupRunner
      else
        raise RuntimeError, "Don't know how to handle run style #{options[:in]}"
      end.new(hosts, connections, &block).run
    end

    private

      attr_accessor :cooldown

      def default_options
        { in: :parallel }
      end

      def connect_hosts!
        Timeout.timeout self.class.connection_timeout, ConnectionTimeoutExpired do
          @connections = [].tap do |threads|
            @hosts.each do |h|
              threads << Thread.new do
                Thread.current[:host] = h
                Thread.current[:connection] = Deploy.config.backend.connect(h)
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
