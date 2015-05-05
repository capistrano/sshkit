require 'time'
require 'helper'

module SSHKit

  class TestCoordinator < UnitTest

    def setup
      super
      @s = String.new
      SSHKit.config.backend = SSHKit::Backend::Printer
    end

    def block_to_run
      lambda do |host|
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
      spy = lambda do |host|
        execute "echo #{host.hostname}"
      end
      String.new.tap do |str|
        SSHKit.capture_output str do
          Coordinator.new(%w{1.example.com}).each &spy
        end
        assert_equal "/usr/bin/env echo 1.example.com", str.strip
      end
    end

    def test_the_connection_manaager_runs_things_in_parallel_by_default
      SSHKit.capture_output @s do
        Coordinator.new(%w{1.example.com 2.example.com}).each &block_to_run
      end
      assert_equal 2, actual_execution_times.length
      assert_within_10_ms(actual_execution_times)
    end

    def test_the_connection_manager_can_run_things_in_sequence
      SSHKit.capture_output @s do
        Coordinator.new(%w{1.example.com 2.example.com}).each in: :sequence, &block_to_run
      end
      assert_equal 2, actual_execution_times.length
      assert_at_least_1_sec_apart(actual_execution_times.first, actual_execution_times.last)
    end

    def test_the_connection_manager_can_run_things_in_sequence_with_wait
      start = Time.now
      SSHKit.capture_output @s do
        Coordinator.new(%w{1.example.com 2.example.com}).each in: :sequence, wait: 10, &block_to_run
      end
      stop = Time.now
      assert_operator (stop - start), :>=, 10.0
    end

    def test_the_connection_manager_can_run_things_in_groups
      SSHKit.capture_output @s do
        Coordinator.new(
          %w{
            1.example.com
            2.example.com
            3.example.com
            4.example.com
            5.example.com
            6.example.com
          }
        ).each in: :groups, &block_to_run
      end
      assert_equal 6, actual_execution_times.length
      assert_within_10_ms(actual_execution_times[0..1])
      assert_within_10_ms(actual_execution_times[2..3])
      assert_within_10_ms(actual_execution_times[4..5])
      assert_at_least_1_sec_apart(actual_execution_times[1], actual_execution_times[2])
      assert_at_least_1_sec_apart(actual_execution_times[3], actual_execution_times[4])
    end

    private

    def assert_at_least_1_sec_apart(first_time, last_time)
      assert_operator (last_time - first_time), :>, 1.0
    end

    def assert_within_10_ms(array)
      assert_in_delta *array, 0.01 # 10 msec
    end

    def actual_execution_times
      @s.lines.collect do |line|
        line.split(' ').last.to_f
      end
    end

  end

end
