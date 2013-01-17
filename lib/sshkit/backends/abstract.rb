module SSHKit
  module Backend

    MethodUnavailableError = Class.new(SSHKit::StandardError)

    class Abstract

      attr_reader :host

      def run
        # Nothing to do
      end

      def initialize(host, &block)
        raise "Must pass a Host object" unless host.is_a? Host
        @host  = host
        @block = block
      end

      def make(commands=[])
        raise MethodUnavailableError
      end

      def rake(commands=[])
        raise MethodUnavailableError
      end

      def background(command, args=[])
        raise MethodUnavailableError
      end

      def test(command, args=[])
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
          if test ! -d #{File.join(@pwd)}
            then echo "Directory does not exist '#{File.join(@pwd)}'" 1>&2
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

      def as(user, &block)
        @user = user
        execute <<-EOTEST
          if ! sudo su #{user} -c whoami > /dev/null
            then echo "You cannot switch to user '#{user}' using sudo, please check the sudoers file" 1>&2
            false
          fi
        EOTEST
        yield
      ensure
        remove_instance_variable(:@user)
      end

      private

      def command(*args)
        options = args.extract_options!
        SSHKit::Command.new(*[*args, options.merge({in: @pwd.nil? ? nil : File.join(@pwd), env: @env, host: @host, user: @user})])
      end

      def connection
        raise "No Connection Pool Implementation"
      end

    end
  end
end
