module Deploy
  module Backend

    MethodUnavailableError = Class.new(RuntimeError)

    class Abstract

      def initialize(*args)
        # Nothing here
      end

      def make(commands=[])
        raise MethodUnavailableError
      end

      def rake(commands=[])
        raise MethodUnavailableError
      end

      def execute(command, args=[])
        raise MethodUnavailableError
      end

      def capture(command, args=[])
        raise MethodUnavailableError
      end

      def within(directory, &block)
        (@pwd ||= []).push directory.to_s
        execute <<-EOTEST
          if test ! -d #{File.join(@pwd)}; then
            echo "Directory does not exist '#{File.join(@pwd)}'" 2>&1
            false
          fi
        EOTEST
        yield
      ensure
        @pwd.pop
      end

      def with(environment, &block)
        @_env = (@env ||= {})
        @env = @_env.merge environment
        yield
      ensure
        @env = @_env
        remove_instance_variable(:@_env)
      end

      private

      def command(*args)
        Deploy::Command.new(*args, in: @pwd.nil? ? nil : File.join(@pwd), env: @env)
      end

      def connection
        raise "No Connection Pool Implementation"
      end

    end
  end
end
