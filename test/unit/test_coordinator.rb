require 'time'
require 'helper'

module SSHKit

  class TestCoordinator < UnitTest

    CloseEnough = 0.01; # 10 msec

    def setup
      super
      @s = String.new
      SSHKit.config.backend = SSHKit::Backend::Printer
    end

    def tearddown
      @s = nil
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
      assert_equal 2, results.length
      assert_in_delta *results, CloseEnough
    end

    def test_the_connection_manager_can_run_things_in_sequence
      SSHKit.capture_output @s do
        Coordinator.new(%w{1.example.com 2.example.com}).each in: :sequence, &block_to_run
      end
      assert_equal 2, results.length
      assert_operator (results.last - results.first), :>, 1.0
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
      assert_equal 6, results.length
      assert_in_delta *results[0..1], CloseEnough
      assert_in_delta *results[2..3], CloseEnough
      assert_in_delta *results[4..5], CloseEnough
      assert_operator (results[2] - results[1]), :>, 1.0
      assert_operator (results[4] - results[3]), :>, 1.0
    end

    private

    def results
      @s.lines.collect do |line|
        line.split(' ').last.to_f
      end
    end

  end

end
