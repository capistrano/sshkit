module SSHKit
  module Backend

    class Printer < Abstract

      def execute_command(cmd)
        output << cmd
      end
      alias :upload! :execute
      alias :download! :execute
      alias :test :execute
    end
  end
end
