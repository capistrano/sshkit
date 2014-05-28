module SSHKit

  module Runner

    class Sequential < Abstract
      attr_writer :wait_interval
      def execute
        hosts.each do |host|
          begin
            backend(host, &block).run
          rescue Exception => e
            e2 = ExecuteError.new e
            raise e2, "Exception while executing on host #{host}: #{e.message}" 
          end
          sleep wait_interval
        end
      end
      private
      def wait_interval
        @wait_interval || options[:wait] || 2
      end
    end

  end

end
