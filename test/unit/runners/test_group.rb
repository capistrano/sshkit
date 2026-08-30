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

      def test_waits_only_between_groups
        hosts = Array.new(5) { Host.new(:local) }
        runner = Group.new(hosts, limit: 2, wait: 3) {}
        Parallel.any_instance.stubs(:execute).returns([])
        runner.expects(:sleep).with(3).twice

        assert_equal [nil, nil, nil], runner.execute
      end
    end
  end
end
