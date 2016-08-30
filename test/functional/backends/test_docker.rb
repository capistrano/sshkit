require 'helper'
require 'tempfile'

module SSHKit
  module Backend
    class TestDocker < Minitest::Test
      def docker(&block)
        Docker.new Host.new(docker: {image: 'ruby:slim'}), &block
      end

      def test_run_image
        assert docker.run_image 'busybox'
      end

      def test_run_image_returns_same_container_id_for_same_image
        cid1 = docker.run_image 'busybox'
        cid2 = docker.run_image 'busybox'
        cid3 = docker.run_image 'busybox'
        assert cid1
        assert_equal cid1, cid2
        assert_equal cid1, cid3
      end

      def test_run_image_returns_different_container_id_for_each_image
        cid1 = docker.run_image 'busybox:musl'
        cid2 = docker.run_image 'busybox:glibc'
        cid3 = docker.run_image 'busybox:uclibc'
        assert cid1
        assert cid2
        assert cid3
        assert cid1 != cid2
        assert cid1 != cid3
        assert cid2 != cid3
      end

      def test_run_image_fails_to_run_missing_image
        assert_raises do
          docker.run_image 'do-not-exist-image'
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
        docker.upload! 'Rakefile', '/tmp/Rakefile'
        assert_equal File.size('Rakefile'), docker.capture('stat -c %s /tmp/Rakefile').to_i
      end

      def test_download
        f = Tempfile.new
        docker.download! '/etc/passwd', f
        f.rewind
        assert f.gets.include?('root:x:0:0:')
        assert_equal docker.capture('stat -c %s /etc/passwd').to_i, f.size
      end
    end
  end
end
