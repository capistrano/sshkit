module SSHKit
  module Backend

    class Printer < Abstract

      include SSHKit::CommandHelper

      def run
        instance_exec(host, &@block)
      end

      def execute(*args)
        output << command(*args).to_command + "\n"
      end

      def capture(command, args=[])
        raise MethodUnavailableError
      end

      private

      def output
        SSHKit.config.output
      end

    end
  end
end
