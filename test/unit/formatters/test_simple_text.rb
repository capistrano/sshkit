require 'helper'
require 'sshkit'

module SSHKit
  class TestSimpleText < UnitTest

    def setup
      SSHKit.config.output_verbosity = Logger::DEBUG
    end

    def output
      @_output ||= String.new
    end

    def pretty
      @_simple ||= SSHKit::Formatter::SimpleText.new(output)
    end

    def teardown
      remove_instance_variable :@_simple
      remove_instance_variable :@_output
      SSHKit.reset_configuration!
    end

    def test_logging_fatal
      assert_log("Test\n", Logger::FATAL, 'Test')
    end

    def test_logging_error
      assert_log(output, Logger::ERROR, 'Test')
    end

    def test_logging_warn
      assert_log(output, Logger::WARN, 'Test')
    end

    def test_logging_info
      assert_log(output, Logger::INFO, 'Test')
    end

    def test_logging_debug
      assert_log(output, Logger::DEBUG, 'Test')
    end

    def test_command_lifecycle_logging
      command = SSHKit::Command.new(:a_cmd, 'some args', host: Host.new('localhost'))
      command.stubs(:uuid).returns('aaaaaa')

      pretty << command
      command.started = true
      pretty << command
      command.stdout = 'stdout message'
      pretty << command
      command.stderr = 'stderr message'
      pretty << command
      command.exit_status = 0
      pretty << command

      expected_log_lines = [
        'Running /usr/bin/env a_cmd some args on localhost',
        'Command: /usr/bin/env a_cmd some args',
        "\tstdout message",
        "\tstderr message",
        'Finished in 0.000 seconds with exit status 0 (successful).'
      ]
      assert_equal expected_log_lines, output.split("\n")
    end

    private

    def assert_log(expected_output, level, message)
      pretty << SSHKit::LogMessage.new(level, message)
      assert_equal expected_output, output
    end

  end
end
