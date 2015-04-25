module SSHKit
  module Backend

    class Printer < Abstract

      def execute_command(cmd)
          output << cmd
      end
      alias :upload! :execute
      alias :download! :execute
      alias :test :execute

      def capture(*args)
        String.new.tap { execute(*args) }
      end
      alias :capture! :capture

    end
  end
end
