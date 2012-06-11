module Deploy

  module CommandContexts

    def in(directory, &block)
      CommandContext.new(:in, directory, &block)
    end

    def with(environment, &block)
      CommandContext.new(:with, environment, &block)
    end

  end

end
