require 'helper'
require 'sshkit'

module SSHKit
  class TestPretty < UnitTest

    def setup
      SSHKit.config.output_verbosity = Logger::DEBUG
    end

    def output
      @_output ||= String.new
    end

    def pretty
      @_pretty ||= SSHKit::Formatter::Pretty.new(output)
    end

    def teardown
      remove_instance_variable :@_pretty
      remove_instance_variable :@_output
      SSHKit.reset_configuration!
    end

    def test_logging_fatal
      assert_log("\e[0;31;49mFATAL\e[0m Test\n", Logger::FATAL, "Test")
    end

    def test_logging_error
      assert_log("\e[0;31;49mERROR\e[0m Test\n", Logger::ERROR, "Test")
    end

    def test_logging_warn
      assert_log("\e[0;33;49mWARN\e[0m Test\n", Logger::WARN, "Test")
    end

    def test_logging_info
      assert_log("\e[0;34;49mINFO\e[0m Test\n", Logger::INFO, "Test")
    end

    def test_logging_debug
      assert_log("\e[0;30;49mDEBUG\e[0m Test\n", Logger::DEBUG, "Test")
    end

    def test_command_lifecycle_logging
      command = SSHKit::Command.new(:a_cmd, 'some args', host: Host.new('localhost'))
      command.stubs(:uuid).returns('aaaaaa')
      command.stubs(:runtime).returns(1)
      pretty << command
      command.started = true
      pretty << command
      command.on_stdout('stdout message')
      pretty << command
      command.on_stderr('stderr message')
      pretty << command
      command.exit_status = 0
      pretty << command

      expected_log_lines = [
        "\e[0;34;49mINFO\e[0m [\e[0;32;49maaaaaa\e[0m] Running \e[1;33;49m/usr/bin/env a_cmd some args\e[0m on \e[0;34;49mlocalhost\e[0m",
        "\e[0;30;49mDEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] Command: \e[0;34;49m/usr/bin/env a_cmd some args\e[0m",
        "\e[0;30;49mDEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] \e[0;32;49m\tstdout message\e[0m",
        "\e[0;30;49mDEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] \e[0;31;49m\tstderr message\e[0m",
        "\e[0;34;49mINFO\e[0m [\e[0;32;49maaaaaa\e[0m] Finished in 1.000 seconds with exit status 0 (\e[1;32;49msuccessful\e[0m)."
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
