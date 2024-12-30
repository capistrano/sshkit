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

      def test_waits_for_all_threads_to_finish_on_error
        hosts = [Host.new("deployer@example"), Host.new("deployer@example2"), Host.new("deployer@example3")]
        completed_one, completed_three = false, false
        runner = Parallel.new(hosts) do |host|
          case host.hostname
          when "example"
            sleep 0.1
            completed_one = true
          when "example2"
            raise "Boom!"
          when "example3"
            sleep 0.3
            completed_three = true
          end
        end

        error = assert_raises(SSHKit::Runner::ExecuteError) do
          runner.execute
        end
        assert_match(/deployer@example2/, error.message)
        assert_match(/Boom!/, error.message)
        assert completed_one
        assert completed_three
      end
    end
  end
end
