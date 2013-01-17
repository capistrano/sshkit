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

  end

end
