require 'helper'
require 'sshkit'

module SSHKit
  class TestColor < UnitTest

    def test_responds_to_colorize?
      assert Color.respond_to?(:colorize?)
    end

    def test_not_fails_on_bold_mode
      Color.stubs(:colorize?).returns true
      assert_equal Color.bold("test"), 'test'.bold
    end
  end
end
