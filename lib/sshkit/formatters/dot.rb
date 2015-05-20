module SSHKit

  module Formatter

    class Dot < Abstract

      def write(obj)
        return unless obj.is_a? SSHKit::Command
        if obj.finished?
          original_output << colorize('.', obj.failure? ? :red : :green)
        end
      end

    end

  end

end
