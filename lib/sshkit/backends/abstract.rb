module SSHKit

  module Backend
    class CapturedResult
      attr_reader :stdout, :stderr

      def initialize(success, stdout, stderr)
        @success, @stdout, @stderr = success, stdout, stderr
      end

      def success?
        @success
      end
    end

    MethodUnavailableError = Class.new(SSHKit::StandardError)

    class Abstract

      extend Forwardable
      def_delegators :output, :log, :fatal, :error, :warn, :info, :debug

      attr_reader :host

      def run
        instance_exec(@host, &@block)
      end

      def initialize(host, &block)
        raise "Must pass a Host object" unless host.is_a? Host
        @host  = host
        @block = block
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

      def test_and_capture(*args)
        options = { verbosity: Logger::DEBUG, strip: true, raise_on_non_zero_exit: false }.merge(args.extract_options!)
        cmd = create_command_and_execute(args, options)
        stdout, stderr = cmd.full_stdout, cmd.full_stderr
        if options[:strip]
          stdout = stdout.strip
          stderr = stderr.strip
        end
        CapturedResult.new(cmd.success?, stdout, stderr)
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
      def upload!(local, remote, options = {}) raise MethodUnavailableError end
      def download!(remote, local=nil, options = {}) raise MethodUnavailableError end
      def execute_command(cmd) raise MethodUnavailableError end
      private :execute_command # Can inline after Ruby 2.1

      private

      def output
        SSHKit.config.output
      end

      def create_command_and_execute(args, options)
        command(args, options).tap { |cmd| execute_command(cmd) }
      end

      def command(args, options)
        SSHKit::Command.new(*[*args, options.merge({in: @pwd.nil? ? nil : File.join(@pwd), env: @env, host: @host, user: @user, group: @group})])
      end

    end

  end

end
