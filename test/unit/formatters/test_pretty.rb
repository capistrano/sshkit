require 'helper'

module SSHKit
  class TestPretty < UnitTest

    def setup
      super
      SSHKit.config.output_verbosity = Logger::DEBUG
    end

    def output
      @output ||= StringIO.new
    end

    def pretty
      @pretty ||= SSHKit::Formatter::Pretty.new(output)
    end

    {
      log:   "\e[0;34;49mINFO\e[0m Test\n",
      fatal: "\e[0;31;49mFATAL\e[0m Test\n",
      error: "\e[0;31;49mERROR\e[0m Test\n",
      warn:  "\e[0;33;49mWARN\e[0m Test\n",
      info:  "\e[0;34;49mINFO\e[0m Test\n",
      debug: "\e[0;30;49mDEBUG\e[0m Test\n"
    }.each do |level, expected_output|
      define_method("test_#{level}_output") do
        pretty.send(level, 'Test')
        assert_equal expected_output, output.string
      end
    end

    def test_command_lifecycle_logging
      execute_command_lifecycle

      expected_log_lines = [
        "\e[0;34;49mINFO\e[0m [\e[0;32;49maaaaaa\e[0m] Running \e[1;33;49m/usr/bin/env a_cmd some args\e[0m as \e[0;34;49muser\e[0m@\e[0;34;49mlocalhost\e[0m",
        "\e[0;30;49mDEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] Command: \e[0;34;49m/usr/bin/env a_cmd some args\e[0m",
        "\e[0;30;49mDEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] \e[0;32;49m\tstdout message\e[0m",
        "\e[0;30;49mDEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] \e[0;31;49m\tstderr message\e[0m",
        "\e[0;34;49mINFO\e[0m [\e[0;32;49maaaaaa\e[0m] Finished in 1.000 seconds with exit status 0 (\e[1;32;49msuccessful\e[0m)."
      ]
      assert_equal expected_log_lines, output.string.split("\n")
    end

    private

    def execute_command_lifecycle
      command = SSHKit::Command.new(:a_cmd, 'some args', host: Host.new('user@localhost'))
      command.stubs(:uuid).returns('aaaaaa')
      command.stubs(:runtime).returns(1)
      pretty << command
      command.started = true
      pretty << command
      command.on_stdout(nil, 'stdout message')
      pretty << command
      command.on_stderr(nil, 'stderr message')
      pretty << command
      command.exit_status = 0
      pretty << command
    end

  end
end
