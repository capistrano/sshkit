require 'helper'

module Deploy
  class TestTestBackend < UnitTest

    def test_execute_calls_command_for_each_channel
      role,command = mock,mock
      role.expects(:channels).returns([1,2,3])
      role.expects(:name).times(3).returns(:name)
      TestBackend.new(role, :test).execute
    end
  end
end
