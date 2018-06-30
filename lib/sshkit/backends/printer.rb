module SSHKit
  module Backend

    # Printer is used to implement --dry-run in Capistrano
    class Printer < Abstract

      def execute_command(cmd)
        output.log_command_start(cmd.with_redaction)
      end

      alias :upload! :execute
      alias :download! :execute

      def test(*)
        super
        true
      end
    end
  end
end
