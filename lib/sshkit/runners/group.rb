module SSHKit

  module Runner

    class Group < Sequential
      attr_accessor :group_size

      def initialize(hosts, options = nil, &block)
        super(hosts, options, &block)
        @group_size = @options[:limit] || 2
      end

      def execute
        hosts.each_slice(group_size).collect do |group_hosts|
          Parallel.new(group_hosts, &block).execute
          sleep wait_interval
        end.flatten
      end

    end

  end

end
