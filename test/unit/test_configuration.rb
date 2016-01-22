require 'helper'

module SSHKit

  class TestConfiguration < UnitTest

    def setup
      super
      SSHKit.config.command_map.clear
      SSHKit.config.output = SSHKit::Formatter::Pretty.new($stdout)
    end

    def test_deprecation_output
      output = ''
      SSHKit.config.deprecation_output = output
      SSHKit.config.deprecation_logger.log('Test')
      assert_equal "[Deprecated] Test\n", output.lines.first
    end

    def test_default_deprecation_output
      SSHKit.config.deprecation_logger.log('Test')
    end

    def test_nil_deprecation_output
      SSHKit.config.deprecation_output = nil
      SSHKit.config.deprecation_logger.log('Test')
    end

    def test_output
      assert SSHKit.config.output.is_a? SSHKit::Formatter::Pretty
      assert SSHKit.config.output = $stderr
    end

    def test_umask
      assert SSHKit.config.umask.nil?
      assert SSHKit.config.umask = '007'
      assert_equal '007', SSHKit.config.umask
    end

    def test_output_verbosity
      assert_equal Logger::INFO, SSHKit.config.output_verbosity
      assert SSHKit.config.output_verbosity = :debug
      assert_equal Logger::DEBUG, SSHKit.config.output_verbosity
      assert SSHKit.config.output_verbosity = Logger::INFO
      assert_equal Logger::INFO, SSHKit.config.output_verbosity
      assert SSHKit.config.output_verbosity = 0
      assert_equal Logger::DEBUG, SSHKit.config.output_verbosity
    end

    def test_default_env
      assert SSHKit.config.default_env
    end

    def test_default_runner
      assert_equal :parallel, SSHKit.config.default_runner
      SSHKit.config.default_runner = :sequence
      assert_equal :sequence, SSHKit.config.default_runner
    end

    def test_backend
      assert_equal SSHKit::Backend::Netssh, SSHKit.config.backend
      assert SSHKit.config.backend = SSHKit::Backend::Printer
      assert_equal SSHKit::Backend::Printer, SSHKit.config.backend
    end

    def test_command_map
      assert_equal SSHKit.config.command_map.is_a?(SSHKit::CommandMap), true

      cm = Hash.new { |h,k| h[k] = "/opt/sites/example/current/bin #{k}"}

      assert SSHKit.config.command_map = cm
      assert_equal SSHKit.config.command_map.is_a?(SSHKit::CommandMap), true
      assert_equal "/opt/sites/example/current/bin ruby", SSHKit.config.command_map[:ruby]
    end

    def test_setting_formatter_types
      {
        dot:        SSHKit::Formatter::Dot,
        blackhole:  SSHKit::Formatter::BlackHole,
        simpletext: SSHKit::Formatter::SimpleText,
      }.each do |format, expected_class|
        SSHKit.config.format = format
        assert SSHKit.config.output.is_a? expected_class
      end
    end

    def test_prohibits_unknown_formatter_type_with_exception
      assert_raises(NameError) do
        SSHKit.config.format = :doesnotexist
      end
    end

    def test_options_can_be_provided_to_formatter
      SSHKit.config.use_format(TestFormatter, :color => false)
      formatter = SSHKit.config.output
      assert_instance_of(TestFormatter, formatter)
      assert_equal($stdout, formatter.output)
      assert_equal({ :color => false }, formatter.options)
    end

    class TestFormatter
      attr_accessor :output, :options

      def initialize(output, options={})
        @output = output
        @options = options
      end
    end
  end

end
