require 'helper'
require 'ostruct'

module SSHKit
  module Backend
    class TestConnectionPool < UnitTest

      def setup
        super
        pool.flush_connections
      end

      def pool
        @pool ||= SSHKit::Backend::ConnectionPool.new
      end

      def connect
        ->(*_args) { Object.new }
      end

      def connect_and_close
        ->(*_args) { OpenStruct.new(:closed? => true) }
      end

      def echo_args
        ->(*args) { args }
      end

      def test_default_idle_timeout
        assert_equal 30, pool.idle_timeout
      end

      def test_connection_factory_receives_args
        args = %w(a b c)
        conn = pool.with(echo_args, *args) { |c| c }

        assert_equal args, conn
      end

      def test_connections_are_not_reused_if_not_checked_in
        conn1 = nil
        conn2 = nil

        pool.with(connect, "conn") do |yielded_conn_1|
          conn1 = yielded_conn_1
          conn2 = pool.with(connect, "conn") { |c| c }
        end

        refute_equal conn1, conn2
      end

      def test_connections_are_reused_if_checked_in
        conn1 = pool.with(connect, "conn") {}
        conn2 = pool.with(connect, "conn") {}

        assert_equal conn1, conn2
      end

      def test_connections_are_reused_across_threads_multiple_times
        t1 = Thread.new do
          pool.with(connect, "conn") { |c| c }
        end

        t2 = Thread.new do
          pool.with(connect, "conn") { |c| c }
        end

        t3 = Thread.new do
          pool.with(connect, "conn") { |c| c }
        end

        refute_nil t1.value
        assert_equal t1.value, t2.value
        assert_equal t2.value, t3.value
      end

      def test_zero_idle_timeout_disables_pooling
        pool.idle_timeout = 0

        conn1 = pool.with(connect, "conn") { |c| c }
        conn2 = pool.with(connect, "conn") { |c| c }
        refute_equal conn1, conn2
      end

      def test_expired_connection_is_not_reused
        pool.idle_timeout = 0.1

        conn1 = pool.with(connect, "conn") { |c| c }
        sleep(pool.idle_timeout)
        conn2 = pool.with(connect, "conn") { |c| c }

        refute_equal conn1, conn2
      end

      def test_expired_connection_is_closed
        pool.idle_timeout = 0.1
        conn1 = mock
        conn1.expects(:closed?).twice.returns(false)
        conn1.expects(:close)

        pool.with(->(*) { conn1 }, "conn1") {}
        # Pause to allow the background thread to wake and close the conn
        sleep(5 + pool.idle_timeout)
      end

      def test_closed_connection_is_not_reused
        conn1 = pool.with(connect_and_close, "conn") { |c| c }
        conn2 = pool.with(connect, "conn") { |c| c }

        refute_equal conn1, conn2
      end

      def test_connections_with_different_args_are_not_reused
        conn1 = pool.with(connect, "conn1") { |c| c }
        conn2 = pool.with(connect, "conn2") { |c| c }

        refute_equal conn1, conn2
      end

      def test_close_connections
        conn1 = mock
        conn1.expects(:closed?).twice.returns(false)
        conn1.expects(:close)

        conn2 = mock
        conn2.expects(:closed?).returns(false)
        conn2.expects(:close).never

        pool.with(->(*) { conn1 }, "conn1") {}

        # We are using conn2 when close_connections is called, so it should
        # not be closed.
        pool.with(->(*) { conn2 }, "conn2") do
          pool.close_connections
        end
      end
    end
  end
end
