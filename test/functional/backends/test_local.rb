require 'helper'
module SSHKit

  module Backend

    class TestLocal < MiniTest::Unit::TestCase

      def setup
        SSHKit.config.output = SSHKit::Formatter::BlackHole.new($stdout)
      end

      def test_capture
        captured_command_result = ''
        Local.new do
          captured_command_result = capture(:echo, 'foo')
        end.run
        assert_equal 'foo', captured_command_result
      end

      def test_execute_raises_on_non_zero_exit_status_and_captures_stdout_and_stderr
        err = assert_raises SSHKit::Command::Failed do
          Local.new do
            execute :echo, "'Test capturing stderr' 1>&2; false"
          end.run
        end
        assert_equal "echo stdout: Nothing written\necho stderr: Test capturing stderr\n", err.message
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

      def test_execute_command_with_success
        result = false
        local = Local.new do
          result = execute(:echo, :text)
        end
        assert local.run
        assert result
      end

      #def test_exectute_interecative_console
      #  Local.new do
      #    execute(:echo, :text) do |channel, stream, data|
      #      next if data.chomp == input.chomp || data.chomp == ''
      #      print data
      #      channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
      #    end
      #    #execute('read line; echo "$line"', {verbosity: Logger::DEBUG})
      #  end.run
      #end

    end
  end
end
