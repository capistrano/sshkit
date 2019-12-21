require 'helper'

module SSHKit
  class TestPretty < UnitTest

    def setup
      super
      SSHKit.config.output_verbosity = Logger::DEBUG
      Command.any_instance.stubs(:uuid).returns('aaaaaa')
    end

    def output
      @output ||= String.new
    end

    def pretty
      @pretty ||= SSHKit::Formatter::Pretty.new(output)
    end

    {
      log:   "\e[0;34;49m  INFO\e[0m Test\n",
      fatal: "\e[0;31;49m FATAL\e[0m Test\n",
      error: "\e[0;31;49m ERROR\e[0m Test\n",
      warn:  "\e[0;33;49m  WARN\e[0m Test\n",
      info:  "\e[0;34;49m  INFO\e[0m Test\n",
      debug: "\e[0;30;49m DEBUG\e[0m Test\n"
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
        "\e[0;34;49m  INFO\e[0m [\e[0;32;49maaaaaa\e[0m] Running \e[1;33;49m/usr/bin/env a_cmd some args\e[0m as \e[0;34;49muser\e[0m@\e[0;34;49mlocalhost\e[0m",
        "\e[0;30;49m DEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] Command: \e[0;34;49m/usr/bin/env a_cmd some args\e[0m",
        "\e[0;30;49m DEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] \e[0;32;49m\tstdout message\e[0m",
        "\e[0;30;49m DEBUG\e[0m [\e[0;32;49maaaaaa\e[0m] \e[0;31;49m\tstderr message\e[0m",
        "\e[0;34;49m  INFO\e[0m [\e[0;32;49maaaaaa\e[0m] Finished in 1.000 seconds with exit status 0 (\e[1;32;49msuccessful\e[0m)."
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
        assert_log_output expected_output
      end
    end

    def test_logging_message_with_leading_and_trailing_space
      pretty.log("       some spaces\n\n  \t")
      assert_log_output "  INFO some spaces\n"
    end

    def test_can_log_non_strings
      pretty.log(Pathname.new('/var/log/my.log'))
      assert_log_output "  INFO /var/log/my.log\n"
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
      assert_equal('write only supports formatting SSHKit::LogMessage, called with Pathname: #<Pathname:/tmp>', raised_error.message)
    end

    def test_does_not_log_message_when_verbosity_is_too_low
      SSHKit.config.output_verbosity = Logger::WARN
      pretty.info('Some info')
      assert_log_output('')

      SSHKit.config.output_verbosity = Logger::INFO
      pretty.info('Some other info')
      assert_log_output("  INFO Some other info\n")
    end

    def test_does_not_log_command_when_verbosity_is_too_low
      SSHKit.config.output_verbosity = Logger::WARN
      command = Command.new(:ls, host: Host.new('user@localhost'), verbosity: Logger::INFO)
      pretty.log_command_start(command)
      assert_log_output('')

      SSHKit.config.output_verbosity = Logger::INFO
      pretty.log_command_start(command)
      assert_log_output("  INFO [aaaaaa] Running /usr/bin/env ls as user@localhost\n")
    end


    def test_can_write_to_output_which_just_supports_append
      # Note output doesn't have to be an IO, it only needs to support <<
      output = stub(:<< => nil)
      pretty = SSHKit::Formatter::Pretty.new(output)
      simulate_command_lifecycle(pretty)
    end

    private

    def simulate_command_lifecycle(pretty)
      command = SSHKit::Command.new(:a_cmd, 'some args', host: Host.new('user@localhost'))
      command.stubs(:runtime).returns(1)
      pretty.log_command_start(command)
      command.started = true
      command.on_stdout(nil, 'stdout message')
      pretty.log_command_data(command, :stdout, 'stdout message')
      command.on_stderr(nil, 'stderr message')
      pretty.log_command_data(command, :stderr, 'stderr message')
      command.exit_status = 0
      pretty.log_command_exit(command)
    end

    def assert_log_output(expected_output)
      assert_equal expected_output, output
    end

  end
end
