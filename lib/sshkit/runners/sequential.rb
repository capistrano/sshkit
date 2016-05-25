module SSHKit

  module Runner

    class Sequential < Abstract
      attr_accessor :wait_interval

      def initialize(hosts, options = nil, &block)
        super(hosts, options, &block)
        @wait_interval = @options[:wait] || 2
      end

      def execute
        last_host = hosts.pop

        hosts.each do |host|
          run_backend(host, &block)
          sleep wait_interval
        end

        unless last_host.nil?
          run_backend(last_host, &block)
        end
      end

      private
      def run_backend(host, &block)
        backend(host, &block).run
      rescue StandardError => e
        e2 = ExecuteError.new e
        raise e2, "Exception while executing #{host.user ? "as #{host.user}@" : "on host "}#{host}: #{e.message}"
      end

    end

  end

end
