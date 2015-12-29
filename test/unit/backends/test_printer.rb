require 'helper'

module SSHKit
  module Backend
    class TestPrinter < UnitTest

      def setup
        super
        SSHKit.config.output = SSHKit::Formatter::Pretty.new(output)
        SSHKit.config.output_verbosity = Logger::DEBUG
        Command.any_instance.stubs(:uuid).returns('aaaaaa')
      end

      def output
        @output ||= String.new
      end

      def printer
        @printer ||= Printer.new(Host.new('example.com'))
      end

      def test_execute
        printer.execute 'uname -a'
        assert_output_lines(
          '  INFO [aaaaaa] Running uname -a on example.com',
          ' DEBUG [aaaaaa] Command: uname -a'
        )
      end

      def test_test_method
        assert printer.test('[ -d /some/file ]'), 'test should return true'

        assert_output_lines(
          ' DEBUG [aaaaaa] Running [ -d /some/file ] on example.com',
          ' DEBUG [aaaaaa] Command: [ -d /some/file ]'
        )
      end

      def test_capture
        result = printer.capture 'ls -l'

        assert_equal '', result

        assert_output_lines(
          ' DEBUG [aaaaaa] Running ls -l on example.com',
          ' DEBUG [aaaaaa] Command: ls -l'
        )
      end

      def test_upload
        printer.upload! '/some/file', '/remote'
        assert_output_lines(
          '  INFO [aaaaaa] Running /usr/bin/env /some/file /remote on example.com',
          ' DEBUG [aaaaaa] Command: /usr/bin/env /some/file /remote'
        )
      end

      def test_download
        printer.download! 'remote/file', '/local/path'
        assert_output_lines(
          '  INFO [aaaaaa] Running /usr/bin/env remote/file /local/path on example.com',
          ' DEBUG [aaaaaa] Command: /usr/bin/env remote/file /local/path'
        )
      end

      private

      def assert_output_lines(*expected_lines)
        assert_equal(expected_lines, output.split("\n"))
      end
    end
  end
end
