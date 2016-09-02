require 'helper'

module SSHKit
  module Backend
    class TestDocker < UnitTest
      def backend
        @backend ||= Docker
      end

      def docker
        @docker ||= backend.new Host.new(docker: {container: 'container-id'})
      end

      def test_docker_config_options
        backend.configure do |docker|
          docker.pty = true
          docker.use_sudo = true
        end

        assert_equal true, backend.config.pty
        assert_equal true, backend.config.use_sudo
      end

      def test_to_docker_cmd
        backend.configure do |docker|
          docker.pty = false
          docker.use_sudo = false
        end
        cmd = docker.to_docker_cmd(*%w(date +%s))
        assert_equal %w(docker exec), cmd[0, 2]
        assert cmd.member?('container-id')
        assert cmd.member?('+%s')
      end

      def test_to_docker_cmd_with_sudo
        backend.configure do |docker|
          docker.use_sudo = true
        end
        cmd = docker.to_docker_cmd('date')
        assert_equal %w(sudo docker exec), cmd[0, 3]
      end

      def test_to_docker_cmd_with_pty
        backend.configure do |docker|
          docker.pty = true
        end
        cmd = docker.to_docker_cmd('date')
        assert cmd.member?('-it')
      end

      def test_with_pty_will_change_temporarily
        pty = backend.config.pty

        docker.__send__(:with_pty, true) do
          assert_equal true, backend.config.pty
        end
        assert_equal pty, backend.config.pty

        docker.__send__(:with_pty, false) do
          assert_equal false, backend.config.pty
        end
        assert_equal pty, backend.config.pty

        docker.__send__(:with_pty, :hoge) do
          assert_equal :hoge, backend.config.pty
        end
        assert_equal pty, backend.config.pty
      end

      def test_merged_env
        SSHKit.config.default_env = {d1: 'default'}
        d = backend.new Host.new(docker: {container: 'cid', env: 'E_A=V_A'})
        assert_equal d.merged_env, {d1: 'default', E_A: 'V_A'}

        SSHKit.config.default_env = {d1: 'default', same: '1'}
        d = backend.new Host.new(docker: {container: 'cid', env: ['ARRAY=test', 'same=2']})
        assert_equal d.merged_env, {d1: 'default', same: '2', ARRAY: 'test'}

        SSHKit.config.default_env = {d1: 'def'}
        d = backend.new Host.new(docker: {container: 'cid', env: {with: 'hash', d1: 'override'}})
        assert_equal d.merged_env, {d1: 'override', with: 'hash'}
      end

    end
  end
end
