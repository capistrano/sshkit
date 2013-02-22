module SSHKit

  class Configuration

    attr_accessor :umask, :output_verbosity
    attr_writer :output, :backend, :default_env, :command_map

    def output
      @output ||= format=(:pretty)
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
      @command_map ||= begin
        Hash.new do |hash, command|
          if %w{if test time}.include? command.to_s
            hash[command] = command.to_s
          else
            hash[command] = "/usr/bin/env #{command}"
          end
        end
      end
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
