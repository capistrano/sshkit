require 'shellwords'
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
        raise Failed, stderr.empty? ? "No messages written to stderr" : stderr.strip
      end
    end

    def runtime
      return nil unless complete?
      @finished_at - @started_at
    end

    def to_hash
      {
        command:     command,
        args:        args,
        options:     options,
        exit_status: exit_status,
        stdout:      stdout,
        stderr:      stderr,
        started_at:  @started_at,
        finished_at: @finished_at,
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

    def to_s
      return command.to_s if command.match /\s/
      String.new.tap do |cs|
        if options[:in]
          cs << sprintf("cd %s && ", options[:in])
        end
        if options[:env]
          cs << '( '
          options[:env].each do |k,v|
            cs << k.to_s.upcase
            cs << "="
            cs << v.to_s.shellescape
          end
          cs << ' '
        end
        if options[:user]
          cs << "sudo su #{options[:user]} -c "
        end
        if options[:run_in_background]
          cs << 'nohup '
        end
        cs << SSHKit.config.command_map[command.to_sym]
        if args.any?
          cs << ' '
          cs << args.join(' ')
        end
        if options[:run_in_background]
          cs << ' > /dev/null &'
        end
        if options[:env]
          cs << ' )'
        end
      end
    end

    private

      def default_options
        { raise_on_non_zero_exit: true, run_in_background: false }
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
