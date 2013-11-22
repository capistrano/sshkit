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
        SSHKit.config.backend.new(host, &block)
      end

    end

  end

end
