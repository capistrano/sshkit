module SSHKit

  module Formatter

    class Pretty < Abstract

      def write(obj)
        return if obj.respond_to?(:verbosity) && obj.verbosity < SSHKit.config.output_verbosity
        case obj
        when SSHKit::Command    then write_command(obj)
        when SSHKit::LogMessage then write_log_message(obj)
        else
          raise "Output formatter only supports formatting SSHKit::Command and SSHKit::LogMessage, called with #{obj.class}: #{obj.inspect}"
        end
      end
      alias :<< :write

      private

      def write_command(command)
        unless command.started?
          host_prefix = command.host.user ? "as #{colorize(command.host.user, :blue)}@" : 'on '
          write_command_message("Running #{colorize(command, :yellow, :bold)} #{host_prefix}#{colorize(command.host, :blue)}", command)
          if SSHKit.config.output_verbosity == Logger::DEBUG
            write_command_message("Command: #{colorize(command.to_command, :blue)}", command, Logger::DEBUG)
          end
        end

        if SSHKit.config.output_verbosity == Logger::DEBUG
          command.clear_stdout_lines.each do |line|
            write_command_message(colorize(format_std_stream_line(line), :green), command, Logger::DEBUG)
          end

          command.clear_stderr_lines.each do |line|
            write_command_message(colorize(format_std_stream_line(line), :red), command, Logger::DEBUG)
          end
        end

        if command.finished?
          successful_or_failed =  command.failure? ? colorize('failed', :red, :bold) : colorize('successful', :green, :bold)
          write_command_message("Finished in #{sprintf('%5.3f seconds', command.runtime)} with exit status #{command.exit_status} (#{successful_or_failed}).", command)
        end
      end

      def write_command_message(message, command, verbosity_override=nil)
        original_output << "%6s [%s] %s\n" % [level(verbosity_override || command.verbosity), colorize(command.uuid, :green), message]
      end

      def write_log_message(log_message)
        original_output << "%6s %s\n" % [level(log_message.verbosity), log_message.to_s]
      end

      def level(verbosity)
        colorize(level_names(verbosity), level_formatting(verbosity))
      end

      def level_formatting(level_num)
        [:black, :blue, :yellow, :red, :red][level_num]
      end

      def level_names(level_num)
        %w{ DEBUG INFO WARN ERROR FATAL }[level_num]
      end

    end

  end

end
