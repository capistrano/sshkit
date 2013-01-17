require 'thread'

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
