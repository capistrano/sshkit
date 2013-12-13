module SSHKit

  module Runner

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
        @group_size || options[:limit] || 2
      end
    end

  end

end
