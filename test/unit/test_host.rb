require 'helper'

module Deploy

  class TestHost < UnitTest

    def test_raises_on_unparsable_string
      assert_raises UnparsableHostStringError do
        Host.new(":@hello@:")
      end
    end

    def test_regular_hosts
      h = Host.new 'example.com'
      assert_equal 22,            h.port
      assert_equal `whoami`,      h.username
      assert_equal 'example.com', h.hostname
    end

    def test_host_with_port
      h = Host.new 'example.com:2222'
      assert_equal 2222,          h.port
      assert_equal 'example.com', h.hostname
    end

    def test_host_with_username
      h = Host.new 'root@example.com'
      assert_equal 'root',        h.username
      assert_equal 'example.com', h.hostname
    end

    def test_host_with_username_and_port
      h = Host.new 'user@example.com:123'
      assert_equal 123,           h.port
      assert_equal 'user',        h.username
      assert_equal 'example.com', h.hostname
    end

    def test_does_not_confuse_upv6_hosts_with_port_specification
      skip
      h = Host.new '[1fff:0:a88:85a3::ac1f]:8001'
      assert_equal 8001,                    h.port
      assert_equal '1fff:0:a88:85a3::ac1f', h.hostname
    end

  end

end
