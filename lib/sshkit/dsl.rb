module SSHKit

  module DSL

    def on(hosts, options={}, &block)
      Coordinator.new(hosts).each(options, &block)
    end

    def run_locally(&block)
      Backend::Local.new(&block).run
    end

  end

end
