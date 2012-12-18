require 'helper'

module Deploy

  class TestConnectionManager < UnitTest

    def setup
      mbe = Class.new
      mbe.send(:define_method, :connect, lambda { |h| return })
      ConnectionManager.backend = mbe
    end

    def test_connection_manager_handles_a_single_argument
      h = Host.new('1.example.com')
      Host.expects(:new).with('1.example.com').once().returns(h)
      ConnectionManager.new '1.example.com'
    end

    def test_connection_manager_resolves_hosts
      h = Host.new('n.example.com')
      Host.expects(:new).times(3).returns(h)
      ConnectionManager.new %w{1.example.com 2.example.com 3.example.com}
    end

    def test_connection_manager_removes_duplicates_after_resolving_hosts
      cm = ConnectionManager.new %w{user@1.example.com:22 user@1.example.com}
      assert_equal ['user@1.example.com:22'], cm.hosts.map(&:to_s)
    end

    def test_connection_manager_raises_a_connection_timeout_error_if_a_host_takes_too_long_to_respond
      mbe = Class.new
      mbe.send(:define_method, :connect, lambda { |h| sleep 60 })
      ConnectionManager.backend = mbe
      ConnectionManager.connection_timeout = 1
      assert_raises ConnectionTimeoutExpired do
        ConnectionManager.new '1.example.com'
      end
    end

    def test_the_connection_manager_yields_to_the_host_connection_instance_in_each
      spy = lambda do |host, connection|
        assert_equal host, Host.new("1.example.com")
      end
      ConnectionManager.new(%{1.example.com}).each &spy
    end

  end

end
