module SSHKit
  module Backend

    class Printer < Abstract

      include SSHKit::CommandHelper

      def run
        instance_exec(host, &@block)
      end

      def execute(*args)
        command(*args).tap do |cmd|
          output << sprintf("%s\n", cmd)
        end
      end
      alias :upload! :execute
      alias :download! :execute
      alias :test :execute
      alias :invoke :execute

      def capture(*args)
        String.new.tap { execute(*args) }
      end
      alias :capture! :capture

      def full_capture(*args)
        options = args.extract_options!.merge(
          raise_on_non_zero_exit: false,
          verbosity: Logger::DEBUG
        )
        cmd=execute(*[*args, options])
        [cmd.exit_status,cmd.full_stdout.strip,cmd.full_stderr.strip]
      end

      private

      def output
        SSHKit.config.output
      end

    end
  end
end
