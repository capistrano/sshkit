require 'helper'

module SSHKit
  # Try to maintain backwards compatibility with Custom formatters defined by other people
  class TestCustom < UnitTest

    def setup
      super
      SSHKit.config.output_verbosity = Logger::DEBUG
    end

    def output
      @output ||= String.new
    end

    def custom
      @custom ||= CustomFormatter.new(output)
    end

    {
        log:   'LM 1 Test',
        fatal: 'LM 4 Test',
        error: 'LM 3 Test',
        warn:  'LM 2 Test',
        info:  'LM 1 Test',
        debug: 'LM 0 Test'
    }.each do |level, expected_output|
      define_method("test_#{level}_logging") do
        custom.send(level, 'Test')
        assert_log_output expected_output
      end
    end

    def test_write_logs_commands
      custom.write(Command.new(:ls))

      assert_log_output 'C 1 /usr/bin/env ls'
    end

    def test_double_chevron_logs_commands
      custom << Command.new(:ls)

      assert_log_output 'C 1 /usr/bin/env ls'
    end

    def test_accepts_options_hash
      custom = CustomFormatter.new(output, :foo => 'value')
      assert_equal('value', custom.options[:foo])
    end

    private

    def assert_log_output(expected_output)
      assert_equal expected_output, output
    end

  end

  class CustomFormatter < SSHKit::Formatter::Abstract
    def write(obj)
      original_output << \
        case obj
        when SSHKit::Command    then "C #{obj.verbosity} #{obj}"
        when SSHKit::LogMessage then "LM #{obj.verbosity} #{obj}"
        end
    end
    alias :<< :write

  end

end
