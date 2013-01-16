require 'helper'

module SSHKit

  class TestConfiguration < UnitTest

    def setup
      SSHKit.config = nil
      SSHKit.config.command_map.clear
    end

    def test_output
      assert_equal $stdout, SSHKit.config.output
      assert SSHKit.config.output = $stderr
      assert_equal $stderr, SSHKit.config.output
    end

    def test_runner
      assert_equal :parallel, SSHKit.config.runner
      assert SSHKit.config.runner = :sequence
      assert_equal :sequence, SSHKit.config.runner
    end

    def test_format
      assert_equal :dot, SSHKit.config.format
      assert SSHKit.config.format = :pretty
      assert_equal :pretty, SSHKit.config.format
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

  end

end
