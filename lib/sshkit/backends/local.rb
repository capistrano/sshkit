require 'open3'
require 'fileutils'
module SSHKit

  module Backend

    class Local < Printer

      def initialize(_ = nil, &block)
        @host = Host.new(:local) # just for logging
        @block = block
      end

      def run
        instance_exec(@host, &@block)
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

          Open3.popen3(cmd.to_command) do |stdin, stdout, stderr, wait_thr|
            stdout_thread = Thread.new do
              while line = stdout.gets do
                cmd.stdout = line
                cmd.full_stdout += line

                output << cmd
              end
            end

            stderr_thread = Thread.new do
              while line = stderr.gets do
                cmd.stderr = line
                cmd.full_stderr += line

                output << cmd
              end
            end

            stdout_thread.join
            stderr_thread.join

            cmd.exit_status = wait_thr.value.to_i
            cmd.stdout = ''
            cmd.stderr = ''

            output << cmd
          end
        end
      end

    end
  end
end
