require 'helper'
require 'sshkit'

module SSHKit
  class TestCommandMap < UnitTest

    def setup
      SSHKit.reset_configuration!
    end

    def test_defaults
      map = CommandMap.new
      assert_equal map[:rake], "/usr/bin/env rake"
      assert_equal map[:test], "test"
    end

    def test_setter
      map = CommandMap.new
      map[:rake] = "/usr/local/rbenv/shims/rake"
      assert_equal map[:rake], "/usr/local/rbenv/shims/rake"
    end

    def test_prefix
      map = CommandMap.new
      map.prefix[:rake].push("/home/vagrant/.rbenv/bin/rbenv exec")
      map.prefix[:rake].push("bundle exec")

      assert_equal map[:rake], "/home/vagrant/.rbenv/bin/rbenv exec bundle exec rake"
    end

    def test_prefix_unshift
      map = CommandMap.new
      map.prefix[:rake].push("bundle exec")
      map.prefix[:rake].unshift("/home/vagrant/.rbenv/bin/rbenv exec")

      assert_equal map[:rake], "/home/vagrant/.rbenv/bin/rbenv exec bundle exec rake"
    end

  end
end
