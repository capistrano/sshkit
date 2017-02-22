require "helper"
require "sshkit"

module SSHKit
  module Runner
    class TestParallel < UnitTest
      def test_wraps_ruby_standard_error_in_execute_error
        host = Host.new("deployer@example")
        runner = Parallel.new([host]) { raise "oh no!" }
        error = assert_raises(SSHKit::Runner::ExecuteError) do
          runner.execute
        end
        assert_match(/deployer@example/, error.message)
        assert_match(/oh no!/, error.message)
      end
    end
  end
end
