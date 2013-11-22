module SSHKit

  module Runner

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
        @wait_interval || options[:wait] || 2
      end
    end

  end

end
