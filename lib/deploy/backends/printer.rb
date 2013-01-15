module Deploy
  module Backend

    class Printer < Abstract

      include Deploy::CommandHelper

      attr_reader :host

      def initialize(host, &block)
        @host  = host
        @block = block
      end

      def run
        instance_exec(host, &@block)
      end

      def execute(*args)
        output << command(*args)
      end

      def capture(command, args=[])
        raise MethodUnavailableError
      end

      private

      def output
        Deploy.config.output
      end

    end
  end
end
