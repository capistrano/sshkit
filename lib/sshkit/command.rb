require 'digest/sha1'
require 'securerandom'

# @author Lee Hambley
module SSHKit

  # @author Lee Hambley
  class Command

    Failed = Class.new(SSHKit::StandardError)

    attr_reader :command, :args, :options, :started_at, :started, :exit_status, :full_stdout, :full_stderr

    # Initialize a new Command object
    #
    # @param  [Array] A list of arguments, the first is considered to be the
    # command name, with optional variadaric args
    # @return [Command] An un-started command object with no exit staus, and
    # nothing in stdin or stdout
    #
    def initialize(*args)
      raise ArgumentError, "Must pass arguments to Command.new" if args.empty?
      @options = default_options.merge(args.extract_options!)
      @command = sanitize_command(args.shift)
      @args    = args
      @options.symbolize_keys!
      @stdout, @stderr, @full_stdout, @full_stderr = String.new, String.new, String.new, String.new
    end

    def complete?
      !exit_status.nil?
    end
    alias :finished? :complete?

    def started?
      started
    end

    def started=(new_started)
      @started_at = Time.now
      @started = new_started
    end

    def uuid
      @uuid ||= Digest::SHA1.hexdigest(SecureRandom.random_bytes(10))[0..7]
    end

    def success?
      exit_status.nil? ? false : exit_status.to_i == 0
    end
    alias :successful? :success?

    def failure?
      exit_status.to_i > 0
    end
    alias :failed? :failure?

    def stdout
      log_reader_deprecation('stdout')
      @stdout
    end

    def stdout=(new_value)
      log_writer_deprecation('stdout')
      @stdout = new_value
    end

    def stderr
      log_reader_deprecation('stderr')
      @stderr
    end

    def stderr=(new_value)
      log_writer_deprecation('stderr')
      @stderr = new_value
    end

    def on_stdout(channel, data)
      @stdout = data
      @full_stdout += data
      call_interaction_handler(:stdout, data, channel)
    end

    def on_stderr(channel, data)
      @stderr = data
      @full_stderr += data
      call_interaction_handler(:stderr, data, channel)
    end

    def exit_status=(new_exit_status)
      @finished_at = Time.now
      @exit_status = new_exit_status

      if options[:raise_on_non_zero_exit] && exit_status > 0
        message = ""
        message += "#{command} exit status: " + exit_status.to_s + "\n"
        message += "#{command} stdout: " + (full_stdout.strip.empty? ? "Nothing written" : full_stdout.strip) + "\n"
        message += "#{command} stderr: " + (full_stderr.strip.empty? ? 'Nothing written' : full_stderr.strip) + "\n"
        raise Failed, message
      end
    end

    def runtime
      return nil unless complete?
      @finished_at - @started_at
    end

    def to_hash
      {
        command:     self.to_s,
        args:        args,
        options:     options,
        exit_status: exit_status,
        stdout:      full_stdout,
        stderr:      full_stderr,
        started_at:  @started_at,
        finished_at: @finished_at,
        runtime:     runtime,
        uuid:        uuid,
        started:     started?,
        finished:    finished?,
        successful:  successful?,
        failed:      failed?
      }
    end

    def host
      options[:host]
    end

    def verbosity
      if (vb = options[:verbosity])
        case vb
        when Symbol then return Logger.const_get(vb.to_s.upcase)
        when Integer then return vb
        end
      else
        Logger::INFO
      end
    end

    def should_map?
      !command.match(/\s/)
    end

    def within(&_block)
      return yield unless options[:in]
      sprintf("cd #{options[:in]} && %s", yield)
    end

    def environment_hash
      (SSHKit.config.default_env || {}).merge(options[:env] || {})
    end

    def environment_string
      environment_hash.collect do |key,value|
        key_string = key.is_a?(Symbol) ? key.to_s.upcase : key.to_s
        escaped_value = value.to_s.gsub(/"/, '\"')
        %{#{key_string}="#{escaped_value}"}
      end.join(' ')
    end

    def with(&_block)
      return yield unless environment_hash.any?
      "( export #{environment_string} ; #{yield} )"
    end

    def user(&_block)
      return yield unless options[:user]
      "sudo -u #{options[:user]} #{environment_string + " " unless environment_string.empty?}-- sh -c '#{yield}'"
    end

    def in_background(&_block)
      return yield unless options[:run_in_background]
      sprintf("( nohup %s > /dev/null & )", yield)
    end

    def umask(&_block)
      return yield unless SSHKit.config.umask
      sprintf("umask #{SSHKit.config.umask} && %s", yield)
    end

    def group(&_block)
      return yield unless options[:group]
      %Q(sg #{options[:group]} -c "#{yield}")
      # We could also use the so-called heredoc format perhaps:
      #"newgrp #{options[:group]} <<EOC \\\"%s\\\" EOC" % %Q{#{yield}}
    end

    def to_command
      return command.to_s unless should_map?
      within do
        umask do
          with do
            user do
              in_background do
                group do
                  to_s
                end
              end
            end
          end
        end
      end
    end

    def with_redaction
      new_args = args.map{|arg| arg.is_a?(Redaction) ? '[REDACTED]' : arg }
      redacted_cmd = dup
      redacted_cmd.instance_variable_set(:@args, new_args)
      redacted_cmd
    end

    def to_s
      if should_map?
        [SSHKit.config.command_map[command.to_sym], *Array(args)].join(' ')
      else
        command.to_s
      end
    end

    private

    def default_options
      {
        raise_on_non_zero_exit: true,
        run_in_background:      false
      }
    end

    def sanitize_command(cmd)
      cmd.to_s.lines.map(&:strip).join("; ")
    end

    def call_interaction_handler(stream_name, data, channel)
      interaction_handler = options[:interaction_handler]
      interaction_handler = MappingInteractionHandler.new(interaction_handler) if interaction_handler.kind_of?(Hash)
      interaction_handler.on_data(self, stream_name, data, channel) if interaction_handler.respond_to?(:on_data)
    end

    def log_reader_deprecation(stream)
      SSHKit.config.deprecation_logger.log(
        "The #{stream} method on Command is deprecated. " \
        "The @#{stream} attribute will be removed in a future release. Use full_#{stream}() instead."
      )
    end

    def log_writer_deprecation(stream)
      SSHKit.config.deprecation_logger.log(
        "The #{stream}= method on Command is deprecated. The @#{stream} attribute will be removed in a future release."
      )
    end
  end

end
