module Deploy
  module Backend
    class Abstract

      #
      # Should include The Command and Command Contexts
      #

      def connect(host)
      end

      def make(commands=[])
      end

      def rake(commands=[])
      end

      def run(command, args=[])
      end

      def capture(command, args=[])
      end

    end
  end
end
