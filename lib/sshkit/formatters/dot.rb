module SSHKit

  module Formatter

    class Dot < Abstract

      def log_command_exit(command)
        original_output << colorize('.', command.failure? ? :red : :green)
      end

      def write(_obj)
      end

    end

  end

end
