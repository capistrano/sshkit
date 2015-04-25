module SSHKit
  module Backend

    class Printer < Abstract

      def execute(*args)
        command(*args).tap do |cmd|
          output << cmd
        end
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
