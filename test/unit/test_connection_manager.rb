require 'helper'

module Deploy

  class TestConnectionManager < UnitTest

    def setup
      Deploy.config.backend = Deploy::Backend::Abstract
    end

    def test_connection_manager_handles_a_single_argument
      h = Host.new('1.example.com')
      Host.expects(:new).with('1.example.com').once().returns(h)
      ConnectionManager.new '1.example.com'
    end

    def test_connection_manager_resolves_hosts
      h = Host.new('n.example.com')
      Host.expects(:new).times(3).returns(h)
      ConnectionManager.new %w{1.example.com 2.example.com 3.example.com}
    end

    def test_connection_manager_removes_duplicates_after_resolving_hosts
      cm = ConnectionManager.new %w{user@1.example.com:22 user@1.example.com}
      assert_equal ['user@1.example.com:22'], cm.hosts.map(&:to_s)
    end

    def test_the_connection_manager_yields_the_host_to_each_connection_instance
      spy = lambda do |host, connection|
        assert_equal host, Host.new("1.example.com")
      end
      ConnectionManager.new(%w{1.example.com}).each &spy
    end

    def test_the_connection_manaager_runs_things_in_parallel_by_default
      results = []
      command = lambda do |host,connection|
        results << Time.now
      end
      ConnectionManager.new(%w{1.example.com 2.example.com}).each &command
      assert_equal 2, results.length
      assert_equal *results.map(&:to_i)
    end

    def test_the_connection_manager_can_run_things_in_sequence
      results = []
      command = lambda do |host,connection|
        results << Time.now
      end
      ConnectionManager.new(%w{1.example.com 2.example.com}).each(in: :sequence, &command)
      assert_equal 2, results.length
      assert_operator results.first.to_i, :<, results.last.to_i
    end

    def test_the_connection_manager_can_run_things_in_groups
      results = []
      command = lambda do |host,connection|
        debugger
        results << Time.now
      end
      ConnectionManager.new(%w{1.example.com 2.example.com 3.example.com
                               4.example.com 5.example.com 6.example.com}).each(in: :groups, &command)
      assert_equal 6, results.length
      assert_equal *results[0..1].map(&:to_i)
      assert_equal *results[2..3].map(&:to_i)
      assert_equal *results[4..5].map(&:to_i)
      assert_operator results[0].to_i, :<, results[2].to_i
      assert_operator results[3].to_i, :<, results[4].to_i
    end

    def test_slow_host_timeout
      # Ensure that we throw an error and rollback if one host takes an
      # exceptional length of time longer than the others
    end

  end

end
