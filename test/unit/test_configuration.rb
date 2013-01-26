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

    def test_default_env
      assert SSHKit.config.default_env
    end

    def test_backend
      assert_equal SSHKit::Backend::Netssh, SSHKit.config.backend
      assert SSHKit.config.backend = SSHKit::Backend::Printer
      assert_equal SSHKit::Backend::Printer, SSHKit.config.backend
    end

    def test_command_map
      cm = Hash.new { |h,k| h[k] = "/opt/sites/example/current/bin #{k}"}
      assert_equal Hash.new, SSHKit.config.command_map
      assert_equal "/usr/bin/env ruby", SSHKit.config.command_map[:ruby]
      assert SSHKit.config.command_map = cm
      assert_equal cm, SSHKit.config.command_map
      assert_equal "/opt/sites/example/current/bin ruby", SSHKit.config.command_map[:ruby]
    end

    def test_setting_formatter
      assert SSHKit.config.format = :dot
      assert SSHKit.config.output.is_a? SSHKit::Formatter::Dot
    end
  end

end
