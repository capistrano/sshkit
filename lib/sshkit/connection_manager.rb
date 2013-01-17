require 'timeout'

module SSHKit

  module Runner

    class Abstract

      attr_reader :hosts, :block

      def initialize(hosts, &block)
        @hosts       = Array(hosts)
        @block       = block
      end

      private

      def backend(host, &block)
        SSHKit.config.backend.new(host, &block)
      end

    end

    class Parallel < Abstract
      def execute
        threads = []
        hosts.each do |host|
          threads << Thread.new(host) do |h|
            backend(host, &block).run
          end
        end
        threads.map(&:join)
      end
    end

    class Sequential < Abstract
      attr_writer :wait_interval
      def execute
        hosts.each do |host|
          backend(host, &block).run
          sleep wait_interval
        end
      end
      private
      def wait_interval
        @wait_interval ||= 2
      end
    end

    class Group < Sequential
      attr_writer :group_size
      def execute
        hosts.each_slice(group_size).collect do |group_hosts|
          Parallel.new(group_hosts, &block).execute
          sleep wait_interval
        end.flatten
      end
      private
      def group_size
        @group_size ||= 2
      end
    end

  end

end

module SSHKit

  NoValidHosts = Class.new(StandardError)

  class ConnectionManager

    attr_accessor :hosts

    def initialize(raw_hosts)
      @raw_hosts = Array(raw_hosts)
      raise NoValidHosts unless Array(raw_hosts).any?
      resolve_hosts!
    end

    def each(options={}, &block)
      options = default_options.merge(options)
      case options[:in]
      when :parallel then Runner::Parallel
      when :sequence then Runner::Sequential
      when :groups   then Runner::Group
      else
        raise RuntimeError, "Don't know how to handle run style #{options[:in].inspect}"
      end.new(hosts, &block).execute
    end

    private

      attr_accessor :cooldown

      def default_options
        { in: :parallel }
      end

      def resolve_hosts!
        @hosts = @raw_hosts.collect { |rh| rh.is_a?(Host) ? rh : Host.new(rh) }.uniq
      end

  end

end
