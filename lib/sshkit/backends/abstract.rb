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

      def log(messages)
        info(messages)
      end

      def fatal(messages)
        output << LogMessage.new(Logger::FATAL, messages)
      end

      def error(messages)
        output << LogMessage.new(Logger::ERROR, messages)
      end

      def warn(messages)
        output << LogMessage.new(Logger::WARN, messages)
      end

      def info(messages)
        output << LogMessage.new(Logger::INFO, messages)
      end

      def debug(messages)
        output << LogMessage.new(Logger::DEBUG, messages)
      end

      def trace(messages)
        output << LogMessage.new(Logger::TRACE, messages)
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
        execute <<-EOTEST, verbosity: Logger::DEBUG
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

      def as(who, &block)
        if who.is_a? Hash
          @user  = who[:user]  || who["user"]
          @group = who[:group] || who["group"]
        else
          @user  = who
          @group = nil
        end
        execute <<-EOTEST, verbosity: Logger::DEBUG
          if ! sudo su #{@user} -c whoami > /dev/null
            then echo "You cannot switch to user '#{@user}' using sudo, please check the sudoers file" 1>&2
            false
          fi
        EOTEST
        yield
      ensure
        remove_instance_variable(:@user)
        remove_instance_variable(:@group)
      end

      class << self
        def config
          @config ||= OpenStruct.new
        end

        def configure
          yield config
        end
      end

      private

      def command(*args)
        options = args.extract_options!
        SSHKit::Command.new(*[*args, options.merge({in: @pwd.nil? ? nil : File.join(@pwd), env: @env, host: @host, user: @user, group: @group})])
      end

    end

  end

end
