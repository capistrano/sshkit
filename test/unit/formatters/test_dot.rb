require 'helper'

module SSHKit
  class TestDot < UnitTest

    def setup
      super
      SSHKit.config.output_verbosity = Logger::DEBUG
    end

    def output
      @output ||= String.new
    end

    def dot
      @dot ||= SSHKit::Formatter::Dot.new(output)
    end

    %w(fatal error warn info debug).each do |level|
      define_method("test_#{level}_output") do
        dot.send(level, 'Test')
        assert_log_output('')
      end
    end

    def test_log_command_start
      dot.log_command_start(SSHKit::Command.new(:ls))
      assert_log_output('')
    end

    def test_log_command_data
      dot.log_command_data(SSHKit::Command.new(:ls), :stdout, 'Some output')
      assert_log_output('')
    end

    def test_command_success
      output.stubs(:tty?).returns(true)
      command = SSHKit::Command.new(:ls)
      command.exit_status = 0
      dot.log_command_exit(command)
      assert_log_output("\e[0;32;49m.\e[0m")
    end

    def test_command_failure
      output.stubs(:tty?).returns(true)
      command = SSHKit::Command.new(:ls, {raise_on_non_zero_exit: false})
      command.exit_status = 1
      dot.log_command_exit(command)
      assert_log_output("\e[0;31;49m.\e[0m")
    end

    private

    def assert_log_output(expected_output)
      assert_equal expected_output, output
    end
  end
end
