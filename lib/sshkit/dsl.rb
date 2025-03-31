module SSHKit

  module DSL

    def on(hosts, **options, &block)
      Coordinator.new(hosts).each(**options, &block)
    end

    def run_locally(**options, &block)
      Backend::Local.new(**options, &block).run
    end

  end

end
