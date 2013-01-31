require 'term/ansicolor'

module SSHKit

  module Formatter

    class Pretty < Abstract

      def write(obj)
        if obj.is_a? SSHKit::Command

          return if obj.verbosity < SSHKit.config.output_verbosity

          unless obj.started?
            original_output << level(obj.verbosity) + uuid(obj) + "Running #{c.yellow(c.bold(String(obj)))} on #{c.blue(obj.host.to_s)}\n"
            if SSHKit.config.output_verbosity == Logger::DEBUG
              original_output << level(Logger::DEBUG) + uuid(obj) + c.white("Command: #{c.blue(obj.to_command)}") + "\n"
            end
          end

          if SSHKit.config.output_verbosity == Logger::DEBUG
            if obj.complete? && !obj.stdout.empty?
              obj.stdout.lines.each do |line|
                original_output << level(Logger::DEBUG) + uuid(obj) + c.green("\t" + line)
              end
            end

            if obj.complete? && !obj.stderr.empty?
              obj.stderr.lines.each do |line|
                original_output << level(Logger::DEBUG) + uuid(obj) + c.red("\t" + line)
              end
            end
          end

          if obj.finished?
            original_output << level(obj.verbosity) + uuid(obj) + "Finished in #{sprintf('%5.3f seconds', obj.runtime)} command #{c.bold { obj.failure? ? c.red('failed') : c.green('successful') }}.\n"
          end

        else
          original_output << c.black(c.on_yellow("Output formatter doesn't know how to handle #{obj.inspect}\n"))
        end
      end
      alias :<< :write

      private

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
        %w{black blue yellow red red }[level_num]
      end

      def level_names(level_num)
        %w{DEBUG INFO WARN ERROR FATAL}[level_num]
      end

    end

  end

end
