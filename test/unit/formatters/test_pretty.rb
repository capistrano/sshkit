require 'helper'

module SSHKit
  class TestPretty < UnitTest

    def setup
      super
      SSHKit.config.output_verbosity = Logger::DEBUG
    end

    def output
      @output ||= String.new
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
      define_method("test_#{level}_output_with_color") do
        output.stubs(:tty?).returns(true)
        pretty.send(level, 'Test')
        assert_log_output(expected_output)
      end
    end

    def test_command_lifecycle_logging_with_color
      output.stubs(:tty?).returns(true)
      simulate_command_lifecycle(pretty)

      expected_log_lines = [
        "\e[0;34;49mINFO\e[0m [\e[0;32;49maaaaaa\e[0m] Running \e[1;33;49m/usr/bin/env a_cmd some args\e[0m as \e[0;34;49muser\e[0m@\e[0;34;49mlocalhost\e[0m",
        "\e[0;30;49mDEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] Command: \e[0;34;49m/usr/bin/env a_cmd some args\e[0m",
        "\e[0;30;49mDEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] \e[0;32;49m\tstdout message\e[0m",
        "\e[0;30;49mDEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] \e[0;31;49m\tstderr message\e[0m",
        "\e[0;34;49mINFO\e[0m [\e[0;32;49maaaaaa\e[0m] Finished in 1.000 seconds with exit status 0 (\e[1;32;49msuccessful\e[0m)."
      ]
      assert_equal expected_log_lines, output.split("\n")
    end

    {
        log:   "  INFO Test\n",
        fatal: " FATAL Test\n",
        error: " ERROR Test\n",
        warn:  "  WARN Test\n",
        info:  "  INFO Test\n",
        debug: " DEBUG Test\n"
    }.each do |level, expected_output|
      define_method("test_#{level}_output_without_color") do
        pretty.send(level, "Test")
        assert_equal expected_output, output
      end
    end

    def test_command_lifecycle_logging_without_color
      simulate_command_lifecycle(pretty)

      expected_log_lines = [
          '  INFO [aaaaaa] Running /usr/bin/env a_cmd some args as user@localhost',
          ' DEBUG [aaaaaa] Command: /usr/bin/env a_cmd some args',
          " DEBUG [aaaaaa] \tstdout message",
          " DEBUG [aaaaaa] \tstderr message",
          '  INFO [aaaaaa] Finished in 1.000 seconds with exit status 0 (successful).'
      ]

      assert_equal expected_log_lines, output.split("\n")
    end

    def test_unsupported_class
      raised_error = assert_raises RuntimeError do
        pretty << Pathname.new('/tmp')
      end
      assert_equal('Output formatter only supports formatting SSHKit::Command and SSHKit::LogMessage, called with Pathname: #<Pathname:/tmp>', raised_error.message)
    end

    def test_does_not_log_when_verbosity_is_too_low
      output.stubs(:tty?).returns(true)

      SSHKit.config.output_verbosity = Logger::WARN
      pretty.info('Some info')
      assert_log_output('')

      SSHKit.config.output_verbosity = Logger::INFO
      pretty.info('Some other info')
      assert_log_output("\e[0;34;49mINFO\e[0m Some other info\n")
    end

    def test_can_write_to_output_which_just_supports_append
      # Note output doesn't have to be an IO, it only needs to support <<
      output = stub(:<<)
      pretty = SSHKit::Formatter::Pretty.new(output)
      simulate_command_lifecycle(pretty)
    end

    private

    def simulate_command_lifecycle(pretty)
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

    def assert_log_output(expected_output)
      assert_equal expected_output, output
    end

  end
end
