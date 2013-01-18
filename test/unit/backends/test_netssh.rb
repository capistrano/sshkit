require 'helper'

module SSHKit
  module Backend
    class TestNetssh < UnitTest

      def backend
        @backend ||= Netssh.new(Host.new('example.com'))
      end

      def test_net_ssh_configuration_options
        backend.configure do |ssh|
          ssh.pty = true
          ssh.connection_timeout = 30
        end

        assert_equal 30, backend.config.connection_timeout
        assert_equal true, backend.config.pty
      end
    end
  end
end
