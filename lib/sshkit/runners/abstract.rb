module SSHKit

  module Runner

    class Abstract

      attr_reader :hosts, :options, :block, :config

      def initialize(hosts, **options, &block)
        @hosts       = Array(hosts)
        @options     = options
        @block       = block
        @config      = options[:config] || SSHKit.config
      end

      private

      def backend(host, &block)
        if host.local?
          SSHKit::Backend::Local.new(config: config, &block)
        else
          config.backend.new(host, config: config, &block)
        end
      end

    end

  end

end
