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

      def execute(*args)
        command(*args).tap do |cmd|
          output << cmd

          cmd.started = Time.now

          stdout, stderr, exit_status = Open3.capture3(cmd.to_command)

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
