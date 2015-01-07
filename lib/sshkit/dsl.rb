module SSHKit

  module DSL

    def on(hosts, options={}, &block)
      Coordinator.new(hosts).each(options, &block)
    end

    def run_locally(&block)
      SSHKit.config.local_backend.new(&block).run
    end

  end

end

include SSHKit::DSL
