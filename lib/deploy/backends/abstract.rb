module Deploy
  module Backend

    MethodUnavailableError = Class.new(RuntimeError)

    class Abstract

      def connect(host)
        # Nothing to connect *to* in the abstract
        # adapter
      end

      def make(commands=[])
        raise MethodUnavailableError
      end

      def rake(commands=[])
        raise MethodUnavailableError
      end

      def execute(command, args=[])
        raise MethodUnavailableError
      end

      def capture(command, args=[])
        raise MethodUnavailableError
      end

      def within(directory, &block)
        raise "Boom"
      end

      def with(environment, &block)
        raise "Boom"
      end

      private

      def command(command, args=[])
        Deploy::Command.new(command, Array(args))
      end

    end
  end
end
