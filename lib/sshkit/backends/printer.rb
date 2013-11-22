module SSHKit
  module Backend

    class Printer < Abstract

      include SSHKit::CommandHelper

      def run
        instance_exec(host, &@block)
      end

      def execute(*args)
        command(*args).tap do |cmd|
          output << sprintf("%s\n", cmd)
        end
      end
      alias :upload! :execute
      alias :download! :execute
      alias :test :execute
      alias :invoke :execute

      def capture(*args)
        String.new.tap { execute(*args) }
      end
      alias :capture! :capture


      private

      def output
        SSHKit.config.output
      end

    end
  end
end
