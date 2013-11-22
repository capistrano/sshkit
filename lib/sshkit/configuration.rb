module SSHKit

  class Configuration

    attr_accessor :umask, :output_verbosity
    attr_writer :output, :backend, :default_env

    def output
      @output ||= formatter(:pretty)
    end

    def default_env
      @default_env ||= {}
    end

    def backend
      @backend ||= SSHKit::Backend::Netssh
    end

    def output_verbosity
      @output_verbosity ||= logger(:info)
    end

    def output_verbosity=(verbosity)
      @output_verbosity = logger(verbosity)
    end

    def format=(format)
      self.output = formatter(format)
    end

    def command_map
      @command_map ||= SSHKit::CommandMap.new
    end

    def command_map=(value)
      @command_map = SSHKit::CommandMap.new(value)
    end

    private

    def logger(verbosity)
      verbosity.is_a?(Integer) ? verbosity : Logger.const_get(verbosity.upcase)
    end

    def formatter(format)
      SSHKit::Formatter.const_get(format.capitalize).new($stdout)
    end

  end

end
