require 'helper'
require 'ostruct'

module SSHKit
  module Backend
    class TestConnectionPool < UnitTest

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
        conn = pool.create_or_reuse_connection(*args, &echo_args)

        assert_equal args, conn
      end

      def test_connections_are_reused
        conn1 = pool.create_or_reuse_connection("conn", &connect)
        conn2 = pool.create_or_reuse_connection("conn", &connect)

        assert_equal conn1, conn2
      end

      def test_zero_idle_timeout_disables_resuse
        pool.idle_timeout = 0

        conn1 = pool.create_or_reuse_connection("conn", &connect)
        conn2 = pool.create_or_reuse_connection("conn", &connect)

        refute_equal conn1, conn2
      end

      def test_expired_connection_is_not_reused
        pool.idle_timeout = 0.1

        conn1 = pool.create_or_reuse_connection("conn", &connect)
        sleep(pool.idle_timeout)
        conn2 = pool.create_or_reuse_connection("conn", &connect)

        refute_equal conn1, conn2
      end

      def test_closed_connection_is_not_reused
        conn1 = pool.create_or_reuse_connection("conn", &connect_and_close)
        conn2 = pool.create_or_reuse_connection("conn", &connect)

        refute_equal conn1, conn2
      end

      def test_connections_with_different_args_are_not_reused
        conn1 = pool.create_or_reuse_connection("conn1", &connect)
        conn2 = pool.create_or_reuse_connection("conn2", &connect)

        refute_equal conn1, conn2
      end

    end
  end
end
