require 'helper'

module Deploy
  module Backend
    class TestNetssh < UnitTest
      def backend
        Netssh.new(Host.new('example.com'), Proc.new)
      end
      def test_net_ssh_configuration_timeout
        skip "No configuration on the Netssh class yet"
      end
    end
  end
end
