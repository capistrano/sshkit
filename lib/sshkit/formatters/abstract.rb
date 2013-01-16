require 'forwardable'

module SSHKit

  module Formatter

    class Abstract

      extend Forwardable
      attr_reader :original_output
      def_delegators :@original_output, :read, :rewind

      def initialize(oio)
        @original_output = oio
      end

      def write(obj)
        raise "Abstract formatter should not be used directly, maybe you want SSHKit::Formatter::BlackHole"
      end
      alias :<< :write

    end

  end

end
