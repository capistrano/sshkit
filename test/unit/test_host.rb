require 'helper'

module SSHKit

  class TestHost < UnitTest

    def test_raises_on_unparsable_string
      assert_raises UnparsableHostStringError do
        Host.new(":@hello@:")
      end
    end

    def test_regular_hosts
      h = Host.new 'example.com'
      assert_equal 'example.com',  h.hostname
    end

    def test_ipv4_with_username_and_port
      h = Host.new 'user@127.0.0.1:2222'
      assert_equal 2222,        h.port
      assert_equal 'user',      h.username
      assert_equal '127.0.0.1', h.hostname
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

    def test_host_local
      h = Host.new :local
      assert       h.local?
      assert_nil   h.port
      username_candidates = ENV['USER'] || ENV['LOGNAME'] || ENV['USERNAME']
      assert_equal username_candidates, h.username
      assert_equal 'localhost',         h.hostname
    end

    def test_does_not_confuse_ipv6_hosts_with_port_specification
      h = Host.new '[1fff:0:a88:85a3::ac1f]:8001'
      assert_equal 8001,                    h.port
      assert_equal '1fff:0:a88:85a3::ac1f', h.hostname
    end

    def testing_host_casting_to_a_string
      assert_equal "example.com", Host.new('user@example.com:1234').to_s
    end

    def test_assert_hosts_hash_equally
      assert_equal Host.new('example.com').hash, Host.new('example.com').hash
    end

    def test_assert_hosts_compare_equal
      h1 = Host.new('example.com')
      h2 = Host.new('example.com')

      assert h1 == h2
      assert h1.eql? h2
      assert h1.equal? h2
    end

    def test_arbitrary_host_properties
      h = Host.new('example.com')
      assert_equal nil, h.properties.roles
      assert h.properties.roles = [:web, :app]
      assert_equal [:web, :app], h.properties.roles
    end

    def test_setting_up_a_host_with_a_hash
      h = Host.new(hostname: 'example.com', port: 1234, key: "~/.ssh/example_com.key")
      assert_equal "example.com", h.hostname
      assert_equal 1234, h.port
      assert_equal "~/.ssh/example_com.key", h.keys.first
    end

    def test_setting_up_a_host_with_a_hash_raises_on_unknown_keys
      assert_raises ArgumentError do
        Host.new({this_key_doesnt_exist: nil})
      end
    end

    def test_turning_a_host_into_ssh_options
      Host.new('someuser@example.com:2222').tap do |host|
        host.password = "andthisdoesntevenmakeanysense"
        host.keys     = ["~/.ssh/some_key_here"]
        host.netssh_options.tap do |sho|
          assert_equal 2222, sho.fetch(:port)
          assert_equal 'andthisdoesntevenmakeanysense', sho.fetch(:password)
          assert_equal ['~/.ssh/some_key_here'], sho.fetch(:keys)
        end
      end
    end

    def test_host_ssh_options_are_simply_missing_when_they_have_no_value
      Host.new('my_config_is_in_the_ssh_config_file').tap do |host|
        host.netssh_options.tap do |sho|
          refute sho.has_key?(:port)
          refute sho.has_key?(:password)
          refute sho.has_key?(:keys)
          refute sho.has_key?(:user)
        end
      end
    end

    def test_turning_a_host_into_ssh_options_when_extra_options_are_set
      ssh_options = {
        port: 3232,
        keys: %w(/home/user/.ssh/id_rsa),
        forward_agent: false,
        auth_methods: %w(publickey password)
      }
      Host.new('someuser@example.com:2222').tap do |host|
        host.password = "andthisdoesntevenmakeanysense"
        host.keys     = ["~/.ssh/some_key_here"]
        host.ssh_options = ssh_options
        host.netssh_options.tap do |sho|
          assert_equal 3232,                             sho.fetch(:port)
          assert_equal 'andthisdoesntevenmakeanysense',  sho.fetch(:password)
          assert_equal %w(/home/user/.ssh/id_rsa),       sho.fetch(:keys)
          assert_equal false,                            sho.fetch(:forward_agent)
          assert_equal %w(publickey password),           sho.fetch(:auth_methods)
        end
      end
    end

  end

end
