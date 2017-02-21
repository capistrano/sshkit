require "helper"
require "sshkit"

module SSHKit
  module Runner
    class TestGroup < UnitTest
      def test_wraps_ruby_standard_error_in_execute_error
        localhost = Host.new(:local)
        runner = Group.new([localhost]) { raise "oh no!" }
        error = assert_raises(SSHKit::Runner::ExecuteError) do
          runner.execute
        end
        assert_match(/while executing.*localhost/, error.message)
      end
    end
  end
end
