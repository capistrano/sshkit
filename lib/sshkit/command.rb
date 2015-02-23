require 'digest/sha1'
require 'securerandom'

# @author Lee Hambley
module SSHKit

  # @author Lee Hambley
  module CommandHelper

    def rake(tasks=[])
      execute :rake, tasks
    end

    def make(tasks=[])
      execute :make, tasks
    end

    def execute(command, args=[])
      Command.new(command, args)
    end

    private

    def map(command)
      SSHKit.config.command_map[command.to_sym]
    end

  end

  # @author Lee Hambley
  class Command

    Failed = Class.new(SSHKit::StandardError)

    attr_reader :command, :args, :options, :started_at, :started, :exit_status

    attr_accessor :stdout, :stderr
    attr_accessor :full_stdout, :full_stderr

    # Initialize a new Command object
    #
    # @param  [Array] A list of arguments, the first is considered to be the
    # command name, with optional variadaric args
    # @return [Command] An un-started command object with no exit staus, and
    # nothing in stdin or stdout
    #
    def initialize(*args)
      raise ArgumentError, "May not pass no arguments to Command.new" if args.empty?
      @options = default_options.merge(args.extract_options!)
      @command = args.shift.to_s.strip.to_sym
      @args    = args
      @options.symbolize_keys!
      sanitize_command!
      @stdout, @stderr = String.new, String.new
      @full_stdout, @full_stderr = String.new, String.new
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
      if vb = options[:verbosity]
        case vb.class.name
        when 'Symbol' then return Logger.const_get(vb.to_s.upcase)
        when 'Fixnum' then return vb
        end
      else
        Logger::INFO
      end
    end

    def should_map?
      !command.match /\s/
    end

    def within(&block)
      return yield unless options[:in]
      "cd #{options[:in]} && %s" % yield
    end

    def environment_hash
      (SSHKit.config.default_env || {}).merge(options[:env] || {})
    end

    def environment_string
      environment_hash.collect do |key,value|
        if key.is_a? Symbol
          "#{key.to_s.upcase}=#{value}"
        else
          "#{key.to_s}=#{value}"
        end
      end.join(' ')
    end

    def with(&block)
      return yield unless environment_hash.any?
      "( #{environment_string} %s )" % yield
    end

    def user(&block)
      return yield unless options[:user]
      "sudo -u #{options[:user]} #{environment_string + " " unless environment_string.empty?}-- sh -c '%s'" % %Q{#{yield}}
    end

    def in_background(&block)
      return yield unless options[:run_in_background]
      "( nohup %s > /dev/null & )" % yield
    end

    def umask(&block)
      return yield unless SSHKit.config.umask
      "umask #{SSHKit.config.umask} && %s" % yield
    end

    def group(&block)
      return yield unless options[:group]
      "sg #{options[:group]} -c \\\"%s\\\"" % %Q{#{yield}}
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

    def to_s
      [SSHKit.config.command_map[command.to_sym], *Array(args)].join(' ')
    end

    private

    def default_options
      {
        raise_on_non_zero_exit: true,
        run_in_background:      false
      }
    end

    def sanitize_command!
      command.to_s.strip!
      if command.to_s.match("\n")
        @command = String.new.tap do |cs|
          command.to_s.lines.each do |line|
            cs << line.strip
            cs << '; ' unless line == command.to_s.lines.to_a.last
          end
        end
      end
    end

  end

end
