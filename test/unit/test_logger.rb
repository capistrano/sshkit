require 'helper'

module SSHKit

  class TestLogger < UnitTest

    def test_logger_severity_constants
      assert_equal Logger::DEBUG,  0
      assert_equal Logger::INFO,   1
      assert_equal Logger::WARN,   2
      assert_equal Logger::ERROR,  3
      assert_equal Logger::FATAL,  4
    end

  end

end
