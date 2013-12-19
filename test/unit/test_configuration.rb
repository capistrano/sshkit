require 'helper'

module SSHKit

  class TestConfiguration < UnitTest

    def setup
      SSHKit.config = nil
      SSHKit.config.command_map.clear
      SSHKit.config.output = SSHKit::Formatter::Pretty.new($stdout)
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

    def test_setting_formatter_to_dot
      assert SSHKit.config.format = :dot
      assert SSHKit.config.output.is_a? SSHKit::Formatter::Dot
    end
    
    def test_setting_formatter_to_blackhole
      assert SSHKit.config.format = :BlackHole
      assert SSHKit.config.output.is_a? SSHKit::Formatter::BlackHole
    end
  end

end
