require 'forwardable'

module SSHKit

  module Formatter

    class Abstract

      extend Forwardable
      attr_reader :original_output, :options
      def_delegators :@original_output, :read, :rewind
      def_delegators :@color, :colorize

      def initialize(output, options={})
        @original_output = output
        @options = options
        @color = SSHKit::Color.new(output)
      end

      %w(fatal error warn info debug).each do |level|
        define_method(level) do |message|
          write(LogMessage.new(Logger.const_get(level.upcase), message))
        end
      end
      alias :log :info

      def log_command_start(command)
        write(command)
      end

      def log_command_data(command, _stream_type, _stream_data)
        write(command)
      end

      def log_command_exit(command)
        write(command)
      end

      def <<(obj)
        write(obj)
      end

      def write(_obj)
        raise "Abstract formatter should not be used directly, maybe you want SSHKit::Formatter::BlackHole"
      end

    end

  end

end
