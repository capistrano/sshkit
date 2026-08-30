module SSHKit

  module Runner

    class Group < Sequential
      attr_accessor :group_size

      def initialize(hosts, options = nil, &block)
        super(hosts, options, &block)
        @group_size = @options[:limit] || 2
      end

      def execute
        last_group_index = (hosts.length - 1) / group_size
        hosts.each_slice(group_size).with_index.collect do |group_hosts, index|
          Parallel.new(group_hosts, &block).execute
          sleep wait_interval unless index == last_group_index
        end.flatten
      end

    end

  end

end
