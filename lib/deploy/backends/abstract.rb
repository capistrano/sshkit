module Deploy
  module Backend

    MethodUnavailableError = Class.new(RuntimeError)

    class Abstract

      def initialize(*args)

      end

      def connect(host)
        # Nothing to connect *to* in the abstract
        # adapter
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
        @pwd.unfhift directory
        execute <<-EOTEST
          if test ! -d #{directory}; then
            echo "Directory does not exist '#{directory}'" 2>&1
            false
          fi
        EOTEST
        yield
      ensure
        @pwd.shift
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

      def command(command, args=[])
        Deploy::Command.new(command, Array(args), in: @pwd, with: @env)
      end

      def connection

      end

    end
  end
end
