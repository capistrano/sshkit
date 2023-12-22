require 'helper'
require_relative 'netssh_transfer_tests'

module SSHKit
  module Backend
    class TestNetsshSftp < FunctionalTest
      include NetsshTransferTests

      def setup
        super
        SSHKit::Backend::Netssh.configure do |ssh|
          ssh.transfer_method = :sftp
        end
      end
    end
  end
end
