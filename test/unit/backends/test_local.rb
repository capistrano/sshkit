require 'helper'

module SSHKit
  module Backend
    class TestLocal < UnitTest

      def local
        @local ||= Local.new
      end

      def test_host
        assert_equal 'localhost', local.host.to_s
      end

      def test_execute
        assert_equal true, local.execute('uname -a')
        assert_equal true, local.execute
        assert_equal true, local.execute('cd && pwd')
      end

      def test_recursive_download
        Dir.mktmpdir do |dir|
          source = File.join(dir, 'source')
          target = File.join(dir, 'target')
          FileUtils.mkdir_p(source)
          File.write(File.join(source, 'file'), 'contents')

          local.download!(source, target, recursive: true)

          assert_equal 'contents', File.read(File.join(target, 'file'))
        end
      end

      def test_recursive_option_preserves_io_downloads
        Tempfile.create do |source|
          source.write('contents')
          source.flush
          output = StringIO.new

          local.download!(source.path, output, recursive: true)

          assert_equal 'contents', output.string
        end
      end
    end
  end
end
