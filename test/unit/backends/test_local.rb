require 'helper'
require_relative 'test_local_printer'

module SSHKit
  module Backend
    class TestLocal < TestLocalPrinter

      def local
        @local ||= Local.new
      end

      def test_execute
        assert_equal true, local.execute('uname -a')
        assert_equal true, local.execute
        assert_equal true, local.execute('cd && pwd')
      end
    end
  end
end
