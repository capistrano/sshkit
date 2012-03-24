require 'helper'

module Deploy
  class TestRole < UnitTest
    def setup
      @role = Role.new(:web, [1,2,3])
    end

    def test_name_is_readable
      assert_equal :web, @role.name
    end

    def test_channels_is_readable
      assert_equal [1,2,3], @role.channels
    end
  end
end