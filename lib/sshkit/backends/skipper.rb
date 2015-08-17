module SSHKit
  module Backend

    class Skipper < Abstract

      def initialize(&block)
        @block = block
      end

      def execute_command(cmd)
        warn "[SKIPPING] No Matching Host for #{cmd}"
      end
      alias :upload! :execute
      alias :download! :execute
      alias :test :execute

      def info(_messages)
        # suppress all messages except `warn`
      end
      alias :log :info
      alias :fatal :info
      alias :error :info
      alias :debug :info

    end
  end
end
