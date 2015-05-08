module SSHKit

  module Formatter

    class SimpleText < Pretty

      # Historically, SimpleText formatter was used to disable coloring, so we maintain that behaviour
      def colorize(obj, color, mode=nil)
        obj.to_s
      end

      def format_command_message(message, command, verbosity_override=nil)
        message
      end

      def format_log_message(log_message)
        log_message
      end

    end

  end

end
