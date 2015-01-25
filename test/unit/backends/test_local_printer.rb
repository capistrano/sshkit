require 'helper'

module SSHKit
  module Backend
    class TestLocalPrinter < UnitTest

      def local
        @local ||= LocalPrinter.new
      end

      def test_host
        assert_equal 'localhost', local.host.to_s
      end

      def test_execute
        assert local.execute('uname -a')
        assert local.execute
        assert local.execute('cd && pwd')
      end
    end
  end
end
