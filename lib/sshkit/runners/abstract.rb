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
        @_backends ||= Hash.new do |hash, key|
          hash[key] = SSHKit.config.backend.new(host, &block)
        end
        @_backends[host.hash]
      end

    end

  end

end
