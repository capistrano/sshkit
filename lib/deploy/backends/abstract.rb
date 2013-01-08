module Deploy
  module Backend
    class Abstract

      def connect(host, &block)
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
