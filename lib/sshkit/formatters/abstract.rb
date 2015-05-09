require 'forwardable'

module SSHKit

  module Formatter

    class Abstract

      extend Forwardable
      attr_reader :original_output
      def_delegators :@original_output, :read, :rewind
      def_delegators :@color, :colorize

      def initialize(output)
        @original_output = output
        @color = SSHKit::Color.new(output)
      end

      def log(messages)
        info(messages)
      end

      def fatal(messages)
        write_at_log_level(Logger::FATAL, messages)
      end

      def error(messages)
        write_at_log_level(Logger::ERROR, messages)
      end

      def warn(messages)
        write_at_log_level(Logger::WARN, messages)
      end

      def info(messages)
        write_at_log_level(Logger::INFO, messages)
      end

      def debug(messages)
        write_at_log_level(Logger::DEBUG, messages)
      end

      def write(obj)
        raise "Abstract formatter should not be used directly, maybe you want SSHKit::Formatter::BlackHole"
      end
      alias :<< :write

      protected

      def format_std_stream_line(line)
        ("\t" + line).chomp
      end

      private

      def write_at_log_level(level, messages)
        write(LogMessage.new(level, messages))
      end
    end

  end

end
