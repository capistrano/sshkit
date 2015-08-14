module SSHKit

  module Formatter

    class SimpleText < Pretty

      # Historically, SimpleText formatter was used to disable coloring, so we maintain that behaviour
      def colorize(obj, _color, _mode=nil)
        obj.to_s
      end

      def format_message(_verbosity, message, _uuid=nil)
        message
      end

    end

  end

end
