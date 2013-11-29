require 'open3'
module SSHKit

  module Backend

    class Local < Printer

      def initialize(&block)
        @block = block
      end

      def run
        instance_exec(&@block)
      end

      def test(*args)
        options = args.extract_options!.merge(
          raise_on_non_zero_exit: false,
          verbosity: Logger::DEBUG
        )
        _execute(*[*args, options]).success?
      end

      def execute(*args, &block)
        _execute(*args, &block).success?
      end

      def capture(*args)
        options = args.extract_options!.merge(verbosity: Logger::DEBUG)
        _execute(*[*args, options]).full_stdout.strip
      end

      private

      def _execute(*args, &block)
        command(*args).tap do |cmd|
          output << cmd

          cmd.started = Time.now

          stderr, stdout, exit_status = '', '', 0

          Open3.popen3(cmd.to_command) do |sin, sout, serr, wait_thr|

            if block_given?
              Thread.new { while data = sout.readpartial(4096); block.call(sin, data); end }
            else
              stdout = sout.read
              stderr = serr.read
            end

            exit_status = wait_thr.value
          end

          cmd.stdout = stdout
          cmd.full_stdout += stdout

          cmd.stderr = stderr
          cmd.full_stderr += stderr

          cmd.exit_status = exit_status.to_i

          output << cmd
        end
      end

    end
  end
end
