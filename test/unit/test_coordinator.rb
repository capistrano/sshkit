require 'time'
require 'helper'

module SSHKit

  class TestCoordinator < UnitTest

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
        execute "echo #{Time.now}"
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
      assert_equal *results.map(&:to_i)
    end

    def test_the_connection_manager_can_run_things_in_sequence
      SSHKit.capture_output @s do
        Coordinator.new(%w{1.example.com 2.example.com}).each in: :sequence, &block_to_run
      end
      assert_equal 2, results.length
      assert_operator results.first.to_i, :<, results.last.to_i
    end

    def test_the_connection_manager_can_run_things_in_sequence_with_wait
      start = Time.now
      SSHKit.capture_output @s do
        Coordinator.new(%w{1.example.com 2.example.com}).each in: :sequence, wait: 10, &block_to_run
      end
      stop = Time.now
      assert_operator (stop.to_i - start.to_i), :>=, 10
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
      assert_equal *results[0..1].map(&:to_i)
      assert_equal *results[2..3].map(&:to_i)
      assert_equal *results[4..5].map(&:to_i)
      assert_operator results[0].to_i, :<, results[2].to_i
      assert_operator results[3].to_i, :<, results[4].to_i
    end

    private

    def results
      @s.lines.collect do |line|
        Time.parse(line.split[1..-1].join(' '))
      end
    end

  end

end
