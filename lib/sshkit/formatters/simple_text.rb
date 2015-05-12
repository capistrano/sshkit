module SSHKit

  module Formatter

    class SimpleText < Pretty

      # Historically, SimpleText formatter was used to disable coloring, so we maintain that behaviour
      def colorize(obj, color, mode=nil)
        obj.to_s
      end

      def format_message(verbosity, message, uuid=nil)
        message
      end

    end

  end

end
