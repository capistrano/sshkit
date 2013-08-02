require 'helper'
module SSHKit

  module Backend

    class TestLocal < MiniTest::Unit::TestCase

      def setup
        SSHKit.config.output = SSHKit::Formatter::BlackHole.new($stdout)
      end

      def test_execute_raises_on_non_zero_exit_status_and_captures_stdout_and_stderr
        err = assert_raises SSHKit::Command::Failed do
          Local.new do
            execute :echo, "'Test capturing stderr' 1>&2; false"
          end.run
        end
        assert_equal "echo stdout: Nothing written\necho stderr: Test capturing stderr\n", err.message
      end
    end
  end
end
