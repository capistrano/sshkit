module Deploy
  module Backend

    class Printer < Abstract

      include Deploy::CommandHelper

      def initialize(&block)
        instance_eval &block if block_given?
      end

      def execute(command, args=[])
        command(command, args).tap do |c|
          output << c.to_s + "\n"
        end
      end

      def capture(command, args=[])
        raise MethodUnavailableError
      end

      def within(dir, &block)
        super.tap do |thing|
          output << String(thing) + "\n"
        end
      end

      private

      def output
        Deploy.config.output
      end

    end
  end
end
