require 'time'
require 'helper'

module SSHKit

  class TestCoordinator < UnitTest
    def setup
      super
      @output = String.new
      SSHKit.config.output_verbosity = :debug
      SSHKit.config.output = SSHKit::Formatter::SimpleText.new(@output)
      SSHKit.config.backend = SSHKit::Backend::Printer
    end

    def echo_time
      lambda do |_host|
        execute "echo #{Time.now.to_f}"
      end
    end

    def test_the_connection_manager_handles_empty_argument
      Coordinator.new([]).each do
        raise "This should not be executed"
      end
    end

    def test_connection_manager_handles_a_single_argument
      h = Host.new('1.example.com')
      Host.expects(:new).with('1.example.com').once().returns(h)
      Coordinator.new '1.example.com'
    end

    def test_connection_manager_resolves_hosts
      h = Host.new('n.example.com')
      Host.expects(:new).times(3).returns(h)
      Coordinator.new %w{1.example.com 2.example.com 3.example.com}
    end

    def test_the_connection_manager_yields_the_host_to_each_connection_instance
      Coordinator.new(%w{1.example.com}).each do |host|
        execute "echo #{host.hostname}"
      end
      assert_equal "Command: echo 1.example.com\n", actual_output_commands.last
    end

    def test_the_connection_manaager_runs_things_in_parallel_by_default
      Coordinator.new(%w{1.example.com 2.example.com}).each(&echo_time)
      assert_equal 2, actual_execution_times.length
      assert_within_10_ms(actual_execution_times)
    end

    def test_the_connection_manager_can_run_things_in_sequence
      Coordinator.new(%w{1.example.com 2.example.com}).each in: :sequence, &echo_time
      assert_equal 2, actual_execution_times.length
      assert_at_least_1_sec_apart(actual_execution_times.first, actual_execution_times.last)
    end

    class MyRunner < SSHKit::Runner::Parallel
      def execute
        threads = hosts.map do |host|
          Thread.new(host) do |h|
            b = backend(h, &block)
            b.run
            b.warn "custom runner out"
          end
        end
        threads.each(&:join)
      end
    end

    def test_the_connection_manager_can_run_things_in_custom_runner
      begin
        $original_runner = SSHKit.config.default_runner
        SSHKit.config.default_runner = MyRunner

        Coordinator.new(%w{1.example.com 2.example.com}).each(&echo_time)
        assert_equal 2, actual_execution_times.length
        assert_within_10_ms(actual_execution_times)
        assert_match(/custom runner out/, @output)
      ensure
        SSHKit.config.default_runner = $original_runner
      end
    end

    def test_the_connection_manager_can_run_things_with_custom_runner_configs
      begin
        $original_runner = SSHKit.config.default_runner
        SSHKit.config.default_runner = :groups
        $original_runner_config = SSHKit.config.default_runner_config
        SSHKit.config.default_runner_config = { limit: 2, wait: 5 }

        Coordinator.new(
          %w{
            1.example.com
            2.example.com
            3.example.com
            4.example.com
          }
        ).each(&echo_time)
        assert_equal 4, actual_execution_times.length
        assert_within_10_ms(actual_execution_times[0..1])
        assert_within_10_ms(actual_execution_times[2..3])
        assert_at_least_5_sec_apart(actual_execution_times[0], actual_execution_times[2])
        assert_at_least_5_sec_apart(actual_execution_times[1], actual_execution_times[3])
      ensure
        SSHKit.config.default_runner = $original_runner
        SSHKit.config.default_runner_config = $original_runner_config
      end
    end

    def test_the_connection_manager_can_run_things_in_sequence_with_wait
      start = Time.now
      Coordinator.new(%w{1.example.com 2.example.com}).each in: :sequence, wait: 10, &echo_time
      stop = Time.now
      assert_operator(stop - start, :>=, 10.0)
    end

    def test_the_connection_manager_can_run_things_in_groups
      Coordinator.new(
        %w{
          1.example.com
          2.example.com
          3.example.com
          4.example.com
          5.example.com
          6.example.com
        }
      ).each in: :groups, &echo_time
      assert_equal 6, actual_execution_times.length
      assert_within_10_ms(actual_execution_times[0..1])
      assert_within_10_ms(actual_execution_times[2..3])
      assert_within_10_ms(actual_execution_times[4..5])
      assert_at_least_1_sec_apart(actual_execution_times[1], actual_execution_times[2])
      assert_at_least_1_sec_apart(actual_execution_times[3], actual_execution_times[4])
    end

    private

    def assert_at_least_1_sec_apart(first_time, last_time)
      assert_operator(last_time - first_time, :>, 1.0)
    end

    def assert_at_least_5_sec_apart(first_time, last_time)
      assert_operator(last_time - first_time, :>, 5.0)
    end

    def assert_within_10_ms(array)
      assert_in_delta(*array, 0.01) # 10 msec
    end

    def actual_execution_times
      actual_output_commands.map { |line| line.split(' ').last.to_f }
    end

    def actual_output_commands
      @output.lines.select { |line| line.start_with?('Command:') }
    end

  end

end
