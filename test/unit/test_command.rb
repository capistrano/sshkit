require 'helper'

module Deploy
  class TestCommand < UnitTest
    def test_execute_returns_command
      command = Command.new(:test)
      assert_equal :test, command.execute
    end
  end
end