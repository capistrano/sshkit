module SSHKit

  module Formatter

    class Pretty < Abstract

      LEVEL_NAMES = %w{ DEBUG INFO WARN ERROR FATAL }.freeze
      LEVEL_COLORS = [:black, :blue, :yellow, :red, :red].freeze

      def write(obj)
        return if obj.respond_to?(:verbosity) && obj.verbosity < SSHKit.config.output_verbosity
        case obj
        when SSHKit::Command    then write_command(obj)
        when SSHKit::LogMessage then write_message(obj.verbosity, obj.to_s)
        else
          raise "Output formatter only supports formatting SSHKit::Command and SSHKit::LogMessage, " \
                "called with #{obj.class}: #{obj.inspect}"
        end
      end

      protected

      def format_message(verbosity, message, uuid=nil)
        message = "[#{colorize(uuid, :green)}] #{message}" unless uuid.nil?
        level = colorize(Pretty::LEVEL_NAMES[verbosity], Pretty::LEVEL_COLORS[verbosity])
        '%6s %s' % [level, message]
      end

      private

      def write_command(command)
        uuid = command.uuid

        unless command.started?
          host_prefix = command.host.user ? "as #{colorize(command.host.user, :blue)}@" : 'on '
          message = "Running #{colorize(command, :yellow, :bold)} #{host_prefix}#{colorize(command.host, :blue)}"
          write_message(command.verbosity, message, uuid)
          write_debug("Command: #{colorize(command.to_command, :blue)}", uuid)
        end

        write_std_stream_debug(command.clear_stdout_lines, :green, uuid)
        write_std_stream_debug(command.clear_stderr_lines, :red, uuid)

        if command.finished?
          runtime = sprintf('%5.3f seconds', command.runtime)
          successful_or_failed =  command.failure? ? colorize('failed', :red, :bold) : colorize('successful', :green, :bold)
          message = "Finished in #{runtime} with exit status #{command.exit_status} (#{successful_or_failed})."
          write_message(command.verbosity, message, uuid)
        end
      end

      def write_std_stream_debug(lines, color, uuid)
        lines.each do |line|
          write_debug(colorize("\t#{line}".chomp, color), uuid)
        end
      end

      def write_debug(message, uuid)
        write_message(Logger::DEBUG, message, uuid) if SSHKit.config.output_verbosity == Logger::DEBUG
      end

      def write_message(verbosity, message, uuid=nil)
        original_output << "#{format_message(verbosity, message, uuid)}\n"
      end

    end

  end

end
