module SSHKit

  module Formatter

    class Plain < Abstract

      def write(obj)
        return if obj.verbosity < SSHKit.config.output_verbosity
        case obj
        when SSHKit::Command    then write_command(obj)
        when SSHKit::LogMessage then write_log_message(obj)
        else
          original_output << "Output formatter doesn't know how to handle #{obj.class}\n"
        end
      end
      alias :<< :write

      private

      def write_command(command)
        unless command.started?
          original_output << level(command.verbosity) + uuid(command) + "Running #{String(command)} on #{command.host.to_s}\n"
          if SSHKit.config.output_verbosity == Logger::DEBUG
            original_output << level(Logger::DEBUG) + uuid(command) + "Command: #{command.to_command}" + "\n"
          end
        end

        if SSHKit.config.output_verbosity == Logger::DEBUG
          unless command.stdout.empty?
            command.stdout.lines.each do |line|
              original_output << level(Logger::DEBUG) + uuid(command) + "\t" + line
              original_output << "\n" unless line[-1] == "\n"
            end
          end

          unless command.stderr.empty?
            command.stderr.lines.each do |line|
              original_output << level(Logger::DEBUG) + uuid(command) + "\t" + line
              original_output << "\n" unless line[-1] == "\n"
            end
          end
        end

        if command.finished?
          original_output << level(command.verbosity) + uuid(command) + "Finished in #{sprintf('%5.3f seconds', command.runtime)} with exit status #{command.exit_status} (#{  command.failure? ? 'failed' : 'successful' }).\n"
        end
      end

      def write_log_message(log_message)
        original_output << level(log_message.verbosity) + log_message.to_s + "\n"
      end

      def uuid(obj)
        "[#{obj.uuid}] "
      end

      def level(verbosity)
        "[" << level_names(verbosity) << "] "
      end

      def level_names(level_num)
        %w{ DEBUG INFO WARN ERROR FATAL }[level_num]
      end

    end

  end

end
