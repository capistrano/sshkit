require 'helper'

module SSHKit
  class TestSimpleText < UnitTest

    def setup
      super
      SSHKit.config.output_verbosity = Logger::DEBUG
    end

    def output
      @output ||= String.new
    end

    def simple
      @simple ||= SSHKit::Formatter::SimpleText.new(output)
    end

    %w(fatal error warn info debug).each do |level|
      define_method("test_#{level}_output") do
        simple.send(level, 'Test')
        assert_log_output "Test\n"
      end
    end

    def test_logging_message_with_leading_and_trailing_space
      simple.log("       some spaces\n\n  \t")
      assert_log_output "some spaces\n"
    end

    def test_can_log_non_strings
      simple.log(Pathname.new('/var/log/my.log'))
      assert_log_output "/var/log/my.log\n"
    end

    def test_command_lifecycle_logging
      command = SSHKit::Command.new(:a_cmd, 'some args', host: Host.new('user@localhost'))
      command.stubs(:uuid).returns('aaaaaa')
      command.stubs(:runtime).returns(1)

      simple.log_command_start(command)
      command.started = true
      command.on_stdout(nil, 'stdout message')
      simple.log_command_data(command, :stdout, 'stdout message')
      command.on_stderr(nil, 'stderr message')
      simple.log_command_data(command, :stderr, 'stderr message')
      command.exit_status = 0
      simple.log_command_exit(command)

      expected_log_lines = [
        'Running /usr/bin/env a_cmd some args as user@localhost',
        'Command: /usr/bin/env a_cmd some args',
        "\tstdout message",
        "\tstderr message",
        'Finished in 1.000 seconds with exit status 0 (successful).'
      ]
      assert_equal expected_log_lines, output.split("\n")
    end

    def test_unsupported_class
      raised_error = assert_raises RuntimeError do
        simple << Pathname.new('/tmp')
      end
      assert_equal('write only supports formatting SSHKit::LogMessage, called with Pathname: #<Pathname:/tmp>', raised_error.message)
    end

    def test_does_not_log_when_verbosity_is_too_low
      SSHKit.config.output_verbosity = Logger::WARN
      simple.info('Some info')
      assert_log_output('')

      SSHKit.config.output_verbosity = Logger::INFO
      simple.info('Some other info')
      assert_log_output("Some other info\n")
    end

    private

    def assert_log_output(expected_output)
      assert_equal expected_output, output
    end
  end
end
