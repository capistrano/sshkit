require 'helper'

module SSHKit

  module Backend

    class TestPrinter < UnitTest

      def block_to_run
        lambda do |host|
          execute :ls, '-l', '/some/directory'
        end
      end

      def printer
        Printer.new(Host.new(:'example.com'), &block_to_run)
      end

      def setup
        SSHKit.config.output_verbosity = :debug
      end

      def test_simple_printing
        result = StringIO.new
        SSHKit.capture_output(result) do
          printer.run
        end
        result.rewind
        assert_equal "/usr/bin/env ls -l /some/directory\n", result.read
      end

    end

  end

end
