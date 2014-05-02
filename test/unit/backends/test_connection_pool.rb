require 'helper'
require 'ostruct'

module SSHKit
  module Backend
    class TestConnectionPool < UnitTest

      def setup
        pool.flush_connections
      end

      def pool
        @pool ||= SSHKit::Backend::ConnectionPool.new
      end

      def connect
        ->(*args) { Object.new }
      end

      def connect_and_close
        ->(*args) { OpenStruct.new(:closed? => true) }
      end

      def echo_args
        ->(*args) { args }
      end

      def test_default_idle_timeout
        assert_equal 30, pool.idle_timeout
      end

      def test_connection_factory_receives_args
        args = %w(a b c)
        conn = pool.checkout(*args, &echo_args)

        assert_equal args, conn.connection
      end

      def test_connections_are_not_reused_if_not_checked_in
        conn1 = pool.checkout("conn", &connect)
        conn2 = pool.checkout("conn", &connect)

        refute_equal conn1, conn2
      end

      def test_connections_are_reused_if_checked_in
        conn1 = pool.checkout("conn", &connect)
        pool.checkin conn1
        conn2 = pool.checkout("conn", &connect)

        assert_equal conn1, conn2
      end

      def test_connections_are_reused_across_threads_multiple_times
        t1 = Thread.new {
          Thread.current[:conn] = pool.checkout("conn", &connect)
          pool.checkin Thread.current[:conn]
        }.join

        t2 = Thread.new {
          Thread.current[:conn] = pool.checkout("conn", &connect)
          pool.checkin Thread.current[:conn]
        }.join

        t3 = Thread.new {
          Thread.current[:conn] = pool.checkout("conn", &connect)
          pool.checkin Thread.current[:conn]
        }.join

        refute_equal t1[:conn], nil
        assert_equal t1[:conn], t2[:conn]
        assert_equal t2[:conn], t3[:conn]
      end

      def test_zero_idle_timeout_disables_reuse
        pool.idle_timeout = 0

        conn1 = pool.checkout("conn", &connect)
        pool.checkin conn1

        conn2 = pool.checkout("conn", &connect)

        refute_equal conn1, conn2
      end

      def test_expired_connection_is_not_reused
        pool.idle_timeout = 0.1

        conn1 = pool.checkout("conn", &connect)
        pool.checkin conn1
        sleep(pool.idle_timeout)
        conn2 = pool.checkout("conn", &connect)

        refute_equal conn1, conn2
      end

      def test_closed_connection_is_not_reused
        conn1 = pool.checkout("conn", &connect_and_close)
        pool.checkin conn1
        conn2 = pool.checkout("conn", &connect)

        refute_equal conn1, conn2
      end

      def test_connections_with_different_args_are_not_reused
        conn1 = pool.checkout("conn1", &connect)
        pool.checkin conn1
        conn2 = pool.checkout("conn2", &connect)

        refute_equal conn1, conn2
      end

    end
  end
end
