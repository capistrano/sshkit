require 'term/ansicolor'

module SSHKit

  module Formatter

    class Pretty < Abstract

      def write(obj)
        if obj.is_a? SSHKit::Command
          unless obj.started?
            original_output << "[#{c.green(obj.uuid)}] Running #{c.yellow(c.bold(String(obj)))} on #{c.yellow(obj.host.to_s)}\n"
          end
          if obj.complete? && !obj.stdout.empty?
            obj.stdout.lines.each do |line|
              original_output << c.green("\t" + line)
            end
          end
          if obj.complete? && !obj.stderr.empty?
            obj.stderr.lines.each do |line|
              original_output << c.red("\t" + line)
            end
          end
          if obj.finished?
            original_output << "[#{c.green(obj.uuid)}] Finished in #{sprintf('%5.3f seconds', obj.runtime)} command #{c.bold { obj.failure? ? c.red('failed') : c.green('successful') }}.\n"
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

    end

  end

end
