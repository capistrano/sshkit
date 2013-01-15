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
        directories.push dir
        output << String(thing) + "\n"
      ensure
        directories.pop
      end

      private

      def command(command, args=[], options={})
        Command.new command, Array(args), options
      end

      def output
        Deploy.config.output
      end

    end
  end
end
