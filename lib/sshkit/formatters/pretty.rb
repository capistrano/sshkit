require 'term/ansicolor'

module SSHKit

  module Formatter

    class Pretty < Abstract

      def write(obj)
        return if obj.verbosity < SSHKit.config.output_verbosity
        case obj
        when SSHKit::Command    then write_command(obj)
        when SSHKit::LogMessage then write_log_message(obj)
        else
          original_output << c.black(c.on_yellow("Output formatter doesn't know how to handle #{obj.class}\n"))
        end
      end
      alias :<< :write

      private

      def write_command(command)
        unless command.started?
          original_output << level(command.verbosity) + uuid(command) + "Running #{c.yellow(c.bold(String(command)))} on #{c.blue(command.host.to_s)}\n"
          if SSHKit.config.output_verbosity == Logger::DEBUG
            original_output << level(Logger::DEBUG) + uuid(command) + "Command: #{c.blue(command.to_command)}" + "\n"
          end
        end

        if SSHKit.config.output_verbosity == Logger::DEBUG
          unless command.stdout.empty?
            command.stdout.lines.each do |line|
              original_output << level(Logger::DEBUG) + uuid(command) + c.green("\t" + line)
              original_output << "\n" unless line[-1] == "\n"
            end
          end

          unless command.stderr.empty?
            command.stderr.lines.each do |line|
              original_output << level(Logger::DEBUG) + uuid(command) + c.red("\t" + line)
              original_output << "\n" unless line[-1] == "\n"
            end
          end
        end

        if command.finished?
          original_output << level(command.verbosity) + uuid(command) + "Finished in #{sprintf('%5.3f seconds', command.runtime)} with exit status #{command.exit_status} (#{c.bold { command.failure? ? c.red('failed') : c.green('successful') }}).\n"
        end
      end

      def write_log_message(log_message)
        original_output << level(log_message.verbosity) + log_message.to_s + "\n"
      end

      def c
        @c ||= Term::ANSIColor
      end

      def uuid(obj)
        "[#{c.green(obj.uuid)}] "
      end

      def level(verbosity)
        # Insane number here accounts for the control codes added
        # by term-ansicolor
        sprintf "%14s ", c.send(level_formatting(verbosity), level_names(verbosity))
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
