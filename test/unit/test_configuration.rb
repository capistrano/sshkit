require 'helper'

module SSHKit

  class TestConfiguration < UnitTest

    def setup
      Deploy.config = nil
      Deploy.config.command_map.clear
    end

    def test_output
      assert_equal $stdout, Deploy.config.output
      assert Deploy.config.output = $stderr
      assert_equal $stderr, Deploy.config.output
    end

    def test_runner
      assert_equal :parallel, Deploy.config.runner
      assert Deploy.config.runner = :sequence
      assert_equal :sequence, Deploy.config.runner
    end

    def test_format
      assert_equal :dot, Deploy.config.format
      assert Deploy.config.format = :pretty
      assert_equal :pretty, Deploy.config.format
    end

    def test_backend
      assert_equal SSHKit::Backend::Netssh, Deploy.config.backend
      assert Deploy.config.backend = SSHKit::Backend::Printer
      assert_equal SSHKit::Backend::Printer, Deploy.config.backend
    end

    def test_command_map
      cm = Hash.new { |h,k| h[k] = "/opt/sites/example/current/bin #{k}"}
      assert_equal Hash.new, Deploy.config.command_map
      assert_equal "/usr/bin/env ruby", Deploy.config.command_map[:ruby]
      assert Deploy.config.command_map = cm
      assert_equal cm, Deploy.config.command_map
      assert_equal "/opt/sites/example/current/bin ruby", Deploy.config.command_map[:ruby]
    end

  end

end
