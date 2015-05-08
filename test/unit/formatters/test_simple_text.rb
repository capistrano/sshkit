require 'helper'

module SSHKit
  class TestSimpleText < UnitTest

    def setup
      super
      SSHKit.config.output_verbosity = Logger::DEBUG
    end

    def output
      @output ||= StringIO.new
    end

    def simple
      @simple ||= SSHKit::Formatter::SimpleText.new(output)
    end

    %w(fatal error warn info debug).each do |level|
      define_method("test_#{level}_output") do
        simple.send(level, 'Test')
        assert_equal "Test\n", output.string
      end
    end

    def test_command_lifecycle_logging
      command = SSHKit::Command.new(:a_cmd, 'some args', host: Host.new('user@localhost'))
      command.stubs(:uuid).returns('aaaaaa')
      command.stubs(:runtime).returns(1)

      simple << command
      command.started = true
      simple << command
      command.on_stdout(nil, 'stdout message')
      simple << command
      command.on_stderr(nil, 'stderr message')
      simple << command
      command.exit_status = 0
      simple << command

      expected_log_lines = [
        'Running /usr/bin/env a_cmd some args as user@localhost',
        'Command: /usr/bin/env a_cmd some args',
        "\tstdout message",
        "\tstderr message",
        'Finished in 1.000 seconds with exit status 0 (successful).'
      ]
      assert_equal expected_log_lines, output.string.split("\n")
    end

  end
end
