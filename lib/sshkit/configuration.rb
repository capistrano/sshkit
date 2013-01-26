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
      @output_verbosity ||= Logger::INFO
    end

    def format=(format)
      formatter = SSHKit::Formatter.const_get(format.capitalize)
      self.output = formatter.new($stdout)
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

  end

end
