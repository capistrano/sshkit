require 'open3'
require 'fileutils'
require 'sshkit/backends/local_printer'

module SSHKit

  module Backend

    class Local < LocalPrinter

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

      def upload!(local, remote, options = {})
        if local.is_a?(String)
          FileUtils.cp(local, remote)
        else
          File.open(remote, "wb") do |f|
            IO.copy_stream(local, f)
          end
        end
      end

      def download!(remote, local=nil, options = {})
        if local.nil?
          FileUtils.cp(remote, File.basename(remote))
        else
          File.open(remote, "rb") do |f|
            IO.copy_stream(f, local)
          end
        end
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
