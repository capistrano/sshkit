module SSHKit

  module Runner

    class Abstract

      attr_reader :hosts, :options, :block

      def initialize(hosts, options = nil, &block)
        @hosts       = Array(hosts)
        @options     = options || {}
        @block       = block
      end

      private

      def backend(host, &block)
        backend_factory.new(host, &block)
      end

      def backend_factory
        @options[:backend] || SSHKit.config.backend
      end
    end

  end

end
