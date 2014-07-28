require 'helper'

module SSHKit
  module Backend
    class TestLocal < UnitTest

      def local
        @local ||= Local.new
      end

      def test_with_param
        Local.new(Host.new('127.0.0.1'))
      end

      def test_host
        assert_equal 'localhost', local.host.to_s
      end

      def test_execute
        assert_equal true, local.execute('uname -a')
        assert_equal true, local.execute
        assert_equal true, local.execute('cd && pwd')
      end
    end
  end
end
