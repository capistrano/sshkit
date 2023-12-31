require 'helper'
require_relative 'netssh_transfer_tests'

module SSHKit
  module Backend
    class TestNetsshScp < FunctionalTest
      include NetsshTransferTests

      def setup
        super
        SSHKit::Backend::Netssh.configure do |ssh|
          ssh.transfer_method = :scp
        end
      end

      def test_scp_implementation_is_used
        Netssh.new(a_host).send(:with_transfer, nil) do |transfer|
          assert_instance_of Netssh::ScpTransfer, transfer
        end
      end
    end
  end
end
