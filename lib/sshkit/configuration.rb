module SSHKit

  class Configuration

    attr_accessor :umask, :output_verbosity
    attr_writer :output, :backend, :default_env

    def output
      @output ||= formatter(:pretty)
    end

    def deprecation_logger
      self.deprecation_output = $stderr if @deprecation_logger.nil?
      @deprecation_logger
    end

    def deprecation_output=(out)
      @deprecation_logger = DeprecationLogger.new(out)
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
      formatter_class(format).new($stdout)
    end

    def formatter_class(symbol)
      name = symbol.to_s.downcase
      found = SSHKit::Formatter.constants.find do |const|
        const.to_s.downcase == name
      end
      fail NameError, 'Unrecognized SSHKit::Formatter "#{symbol}"' if found.nil?
      SSHKit::Formatter.const_get(found)
    end

  end

end
