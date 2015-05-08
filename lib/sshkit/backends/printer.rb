module SSHKit
  module Backend

    # Printer is used to implement --dry-run in Capistrano
    class Printer < Abstract

      def execute_command(cmd)
        output << cmd
      end

      alias :upload! :execute
      alias :download! :execute
    end
  end
end
