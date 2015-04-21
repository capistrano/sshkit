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
      pretty << SSHKit::LogMessage.new(Logger::FATAL, "Test")
      assert_equal "\e[0;31;49mFATAL\e[0m Test\n", output
    end

    def test_logging_error
      pretty << SSHKit::LogMessage.new(Logger::ERROR, "Test")
      assert_equal "\e[0;31;49mERROR\e[0m Test\n", output
    end

    def test_logging_warn
      pretty << SSHKit::LogMessage.new(Logger::WARN, "Test")
      assert_equal "\e[0;33;49mWARN\e[0m Test\n", output
    end

    def test_logging_info
      pretty << SSHKit::LogMessage.new(Logger::INFO, "Test")
      assert_equal "\e[0;34;49mINFO\e[0m Test\n", output
    end

    def test_logging_debug
      pretty << SSHKit::LogMessage.new(Logger::DEBUG, "Test")
      assert_equal "\e[0;30;49mDEBUG\e[0m Test\n", output
    end

    def test_command_lifecycle_logging
      command = fixed_uid_command('aaaaaa', :a_cmd, 'some args', 'localhost')
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
        "\e[0;34;49mINFO\e[0m [\e[0;32;49maaaaaa\e[0m] Running \e[1;33;49m/usr/bin/env a_cmd some args\e[0m on \e[0;34;49mlocalhost\e[0m",
        "\e[0;30;49mDEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] Command: \e[0;34;49m/usr/bin/env a_cmd some args\e[0m",
        "\e[0;30;49mDEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] \e[0;32;49m\tstdout message\e[0m",
        "\e[0;30;49mDEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] \e[0;31;49m\tstderr message\e[0m",
        "\e[0;34;49mINFO\e[0m [\e[0;32;49maaaaaa\e[0m] Finished in 0.000 seconds with exit status 0 (\e[1;32;49msuccessful\e[0m)."
      ]
      assert_equal expected_log_lines, output.split("\n")
    end

    private

    def fixed_uid_command(constant_uuid, *args, host)
      command = SSHKit::Command.new(*args, host: Host.new(host))
      command.stubs(:uuid).returns(constant_uuid)
      command
    end
  end
end
