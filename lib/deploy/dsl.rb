require_relative '../deploy'

module Deploy

  module DSL

    def on(hosts, options={}, &block)
      ConnectionManager.new(hosts).each(options, &block)
    end

  end

end

include Deploy::DSL
