require 'helper'
require 'tempfile'

module SSHKit
  module Backend
    class TestDocker < Minitest::Test
      def docker(&block)
        Docker.new Host.new(docker: {image: 'ruby:slim'}), &block
      end

      def test_run_image
        assert docker.run_image
      end

      def test_run_image_returns_same_container_id_for_same_image
        cid1 = docker.run_image Host.new(docker: {image: 'busybox'})
        cid2 = docker.run_image Host.new(docker: {image: 'busybox'})
        cid3 = docker.run_image Host.new(docker: {image: 'busybox'})
        assert cid1
        assert_equal cid1, cid2
        assert_equal cid1, cid3
      end

      def test_run_image_returns_different_container_id_for_each_image
        cid1 = docker.run_image Host.new(docker: {image: 'busybox:musl'})
        cid2 = docker.run_image Host.new(docker: {image: 'busybox:glibc'})
        cid3 = docker.run_image Host.new(docker: {image: 'busybox:uclibc'})
        assert cid1
        assert cid2
        assert cid3
        assert cid1 != cid2
        assert cid1 != cid3
        assert cid2 != cid3
      end

      def test_run_image_fails_to_run_missing_image
        assert_raises do
          docker.run_image Host.new(docker: {image: 'do-not-exist-image'})
        end
      end

      def test_capture
        captured_command_result = nil
        docker do |_host|
          captured_command_result = capture(:uname)
        end.run
        assert_includes %W(Linux Darwin), captured_command_result
      end

      def test_execute
        assert_equal true, docker.execute('date')
      end

      def test_raise_on_execute_fails
        assert_raises SSHKit::Command::Failed do
          docker.execute('/bin/false')
        end
      end

      def test_upload
        c_size = nil
        docker do |_host|
          upload! 'Rakefile', '/tmp/Rakefile'
          c_size = capture('stat -c %s /tmp/Rakefile').to_i
        end.run
        assert_equal File.size('Rakefile'), c_size
      end

      def test_download
        f = Tempfile.new
        c_size = nil
        docker do |host|
          download! '/etc/passwd', f
          c_size = capture('stat -c %s /etc/passwd').to_i
        end.run
        assert_equal c_size, f.size
        f.rewind
        assert f.gets.include?('root:x:0:0:')
      end

      def test_commit
        try_commit_id = "commit-test-#{$$}-#{rand}"
        ret_commit_id = nil
        Docker.new(Host.new(docker: {image: 'busybox', commit: try_commit_id})) do |host|
          upload! '/etc/hostname', '/tmp/hostname'
          ret_commit_id = docker_commit
        end.run
        assert ret_commit_id
        assert_equal try_commit_id, ret_commit_id

        ret_commit_id and
          system *%W(docker rmi #{ret_commit_id}), out: :close
      end

      def test_commit_without_name
        ret_commit_id = nil
        Docker.new(Host.new(docker: {image: 'busybox', commit: true})) do |host|
          upload! '/etc/hostname', '/tmp/hostname'
          ret_commit_id = docker_commit
        end.run
        assert ret_commit_id

        ret_commit_id and
          system *%W(docker rmi #{ret_commit_id}), out: :close
      end

      def test_commit_with_options
        try_commit_id = "commit-test-#{$$}-#{rand}"
        ret_commit_id = nil
        Docker.new(Host.new(docker: {image: 'busybox', commit: {author: 'hoge', name: try_commit_id}})) do |host|
          upload! '/etc/hostname', '/tmp/hostname'
          ret_commit_id = docker_commit
        end.run
        assert ret_commit_id
        assert_equal try_commit_id, ret_commit_id

        ret_commit_id and
          system *%W(docker rmi #{ret_commit_id}), out: :close
      end

      def test_commit_with_runtime_option
        try_commit_id = "commit-test-#{$$}-#{rand}"
        ret_commit_id = nil
        docker do |host|
          upload! '/etc/hostname', '/tmp/hostname'
          ret_commit_id = docker_commit(try_commit_id)
        end.run
        assert ret_commit_id
        assert_equal try_commit_id, ret_commit_id

        ret_commit_id and
          system *%W(docker rmi #{ret_commit_id}), out: :close
      end
    end
  end
end
