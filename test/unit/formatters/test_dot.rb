require 'helper'
require 'sshkit'

module SSHKit
  class TestDot < UnitTest

    def setup
      SSHKit.config.output_verbosity = Logger::DEBUG
    end

    def output
      @_output ||= String.new
    end

    def dot
      @_dot ||= SSHKit::Formatter::Dot.new(output)
    end

    def teardown
      remove_instance_variable :@_dot
      remove_instance_variable :@_output
      SSHKit.reset_configuration!
    end

    def test_logging_fatal
      dot << SSHKit::LogMessage.new(Logger::FATAL, "Test")
      assert_equal "", output.strip
    end

    def test_logging_error
      dot << SSHKit::LogMessage.new(Logger::ERROR, "Test")
      assert_equal "", output.strip
    end

    def test_logging_warn
      dot << SSHKit::LogMessage.new(Logger::WARN, "Test")
      assert_equal "", output.strip
    end

    def test_logging_info
      dot << SSHKit::LogMessage.new(Logger::INFO, "Test")
      assert_equal "", output.strip
    end

    def test_logging_debug
      dot << SSHKit::LogMessage.new(Logger::DEBUG, "Test")
      assert_equal "", output.strip
    end
    
    def test_command_success
      command = SSHKit::Command.new(:ls)
      command.exit_status = 0
      dot << command
      assert_equal "\e[32m.\e[0m", output.strip
    end
    
    def test_command_failure
      command = SSHKit::Command.new(:ls, {raise_on_non_zero_exit: false})
      command.exit_status = 1
      dot << command
      assert_equal "\e[31m.\e[0m", output.strip
    end

  end
end
