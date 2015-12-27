require 'helper'
module SSHKit

  module Backend

    class TestLocal < Minitest::Test

      def setup
        super
        SSHKit.config.output = SSHKit::Formatter::BlackHole.new($stdout)
      end

      def test_capture
        captured_command_result = ''
        Local.new do
          captured_command_result = capture(:echo, 'foo', strip: false)
        end.run
        assert_equal "foo\n", captured_command_result
      end

      def test_execute_raises_on_non_zero_exit_status_and_captures_stdout_and_stderr
        err = assert_raises SSHKit::Command::Failed do
          Local.new do
            execute :echo, "'Test capturing stderr' 1>&2; false"
          end.run
        end
        assert_equal "echo exit status: 256\necho stdout: Nothing written\necho stderr: Test capturing stderr\n", err.message
      end

      def test_test
        succeeded_test_result = failed_test_result = nil
        Local.new do
          succeeded_test_result = test('[ -d ~ ]')
          failed_test_result    = test('[ -f ~ ]')
        end.run
        assert_equal true,  succeeded_test_result
        assert_equal false, failed_test_result
      end

      def test_interaction_handler
        captured_command_result = nil
        Local.new do
          command = 'echo Enter Data; read the_data; echo Captured $the_data;'
          captured_command_result = capture(command, interaction_handler: {
            "Enter Data\n" => "SOME DATA\n",
            "Captured SOME DATA\n" => nil
          })
        end.run
        assert_equal("Enter Data\nCaptured SOME DATA", captured_command_result)
      end
    end
  end
end
