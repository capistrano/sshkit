
module SSHKit

  module Formatter

    class SimpleText < Abstract

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
          original_output << "Running #{String(command)} #{command.host.user ? "as #{command.host.user}@" : "on "}#{command.host}\n"
          if SSHKit.config.output_verbosity == Logger::DEBUG
            original_output << "Command: #{command.to_command}" + "\n"
          end
        end

        if SSHKit.config.output_verbosity == Logger::DEBUG
          unless command.stdout.empty?
            command.stdout.lines.each do |line|
              original_output << "\t" + line
              original_output << "\n" unless line[-1] == "\n"
            end
          end

          unless command.stderr.empty?
            command.stderr.lines.each do |line|
              original_output << "\t" + line
              original_output << "\n" unless line[-1] == "\n"
            end
          end
        end

        if command.finished?
          original_output << "Finished in #{sprintf('%5.3f seconds', command.runtime)} with exit status #{command.exit_status} (#{ command.failure? ? 'failed' : 'successful' }).\n"
        end
      end

      def write_log_message(log_message)
        original_output << log_message.to_s + "\n"
      end

    end

  end

end
