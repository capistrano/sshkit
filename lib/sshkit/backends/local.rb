require 'open3'
module SSHKit

  module Backend

    class Local < Printer

      def initialize(&block)
        @host = Host.new(hostname: 'localhost') # just for logging
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

      def execute(*args)
        _execute(*args).success?
      end

      def capture(*args)
        options = { verbosity: Logger::DEBUG }.merge(args.extract_options!)
        _execute(*[*args, options]).full_stdout
      end

      private

      def _execute(*args)
        command(*args).tap do |cmd|
          output << cmd

          cmd.started = Time.now

          stdout, stderr, exit_status =
            if RUBY_ENGINE == 'jruby'
              _, o, e, t = Open3.popen3('/usr/bin/env', 'sh', '-c', cmd.to_command)
              [o.read, e.read, t.value]
            else
              Open3.capture3(cmd.to_command)
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
