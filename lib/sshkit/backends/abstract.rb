module SSHKit

  module Backend

    MethodUnavailableError = Class.new(SSHKit::StandardError)

    # The Backend instance that is running in the current thread. If no Backend
    # is running, returns `nil` instead.
    #
    # Example:
    #
    #   on(:local) do
    #     self == SSHKit::Backend.current # => true
    #   end
    #
    def self.current
      Thread.current["sshkit_backend"]
    end

    class Abstract

      extend Forwardable
      def_delegators :output, :log, :fatal, :error, :warn, :info, :debug

      attr_reader :host

      def run
        Thread.current["sshkit_backend"] = self
        instance_exec(@host, &@block)
      ensure
        Thread.current["sshkit_backend"] = nil
      end

      def initialize(host, &block)
        raise "Must pass a Host object" unless host.is_a? Host
        @host  = host
        @block = block

        @pwd   = nil
        @env   = nil
        @user  = nil
        @group = nil
      end

      def make(commands=[])
        execute :make, commands
      end

      def rake(commands=[])
        execute :rake, commands
      end

      def test(*args)
        options = args.extract_options!.merge(raise_on_non_zero_exit: false, verbosity: Logger::DEBUG)
        create_command_and_execute(args, options).success?
      end

      def capture(*args)
        options = { verbosity: Logger::DEBUG, strip: true }.merge(args.extract_options!)
        result = create_command_and_execute(args, options).full_stdout
        options[:strip] ? result.strip : result
      end

      def background(*args)
        SSHKit.config.deprecation_logger.log(
          'The background method is deprecated. Blame badly behaved pseudo-daemons!'
        )
        options = args.extract_options!.merge(run_in_background: true)
        create_command_and_execute(args, options).success?
      end

      def execute(*args)
        options = args.extract_options!
        create_command_and_execute(args, options).success?
      end

      def within(directory, &_block)
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

      def with(environment, &_block)
        env_old = (@env ||= {})
        @env = env_old.merge environment
        yield
      ensure
        @env = env_old
      end

      def as(who, &_block)
        if who.is_a? Hash
          @user  = who[:user]  || who["user"]
          @group = who[:group] || who["group"]
        else
          @user  = who
          @group = nil
        end
        execute <<-EOTEST, verbosity: Logger::DEBUG
          if ! sudo -u #{@user} whoami > /dev/null
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

      # Backends which extend the Abstract backend should implement the following methods:
      def upload!(_local, _remote, _options = {}) raise MethodUnavailableError end
      def download!(_remote, _local=nil, _options = {}) raise MethodUnavailableError end
      def execute_command(_cmd) raise MethodUnavailableError end
      private :execute_command # Can inline after Ruby 2.1

      private

      def output
        SSHKit.config.output
      end

      def create_command_and_execute(args, options)
        command(args, options).tap { |cmd| execute_command(cmd) }
      end

      def pwd_path
        if @pwd.nil? || @pwd.empty?
          nil
        else
          File.join(@pwd)
        end
      end

      def command(args, options)
        SSHKit::Command.new(*[*args, options.merge({in: pwd_path, env: @env, host: @host, user: @user, group: @group})])
      end

    end

  end

end
