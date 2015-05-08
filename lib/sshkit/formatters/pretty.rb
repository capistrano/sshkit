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
          host_prefix = command.host.user ? "as #{c.blue(command.host.user)}@" : 'on '
          write_command_message("Running #{c.yellow(c.bold(String(command)))} #{host_prefix}#{c.blue(command.host.to_s)}", command)
          if SSHKit.config.output_verbosity == Logger::DEBUG
            write_command_message("Command: #{c.blue(command.to_command)}", command, Logger::DEBUG)
          end
        end

        if SSHKit.config.output_verbosity == Logger::DEBUG
          command.clear_stdout_lines.each do |line|
            write_command_message(c.green(format_std_stream_line(line)), command, Logger::DEBUG)
          end

          command.clear_stderr_lines.each do |line|
            write_command_message(c.red(format_std_stream_line(line)), command, Logger::DEBUG)
          end
        end

        if command.finished?
          successful_or_failed = c.bold { command.failure? ? c.red('failed') : c.green('successful') }
          write_command_message("Finished in #{sprintf('%5.3f seconds', command.runtime)} with exit status #{command.exit_status} (#{successful_or_failed}).", command)
        end
      end

      def write_command_message(message, command, verbosity_override=nil)
        original_output << "%6s [%s] %s\n" % [level(verbosity_override || command.verbosity), c.green(command.uuid), message]
      end

      def write_log_message(log_message)
        original_output << "%6s %s\n" % [level(log_message.verbosity), log_message.to_s]
      end

      def c
        @c ||= Color
      end

      def level(verbosity)
        c.send(level_formatting(verbosity), level_names(verbosity))
      end

      def level_formatting(level_num)
        %w{ black blue yellow red red }[level_num]
      end

      def level_names(level_num)
        %w{ DEBUG INFO WARN ERROR FATAL }[level_num]
      end

    end

  end

end
