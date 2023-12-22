require 'securerandom'

module SSHKit
  module Backend
    module NetsshTransferTests
      def setup
        super
        @output = String.new
        SSHKit.config.output_verbosity = :debug
        SSHKit.config.output = SSHKit::Formatter::SimpleText.new(@output)
      end

      def a_host
        VagrantWrapper.hosts['one']
      end

      def test_upload_and_then_capture_file_contents
        actual_file_contents = ""
        file_name = File.join("/tmp", SecureRandom.uuid)
        File.open file_name, 'w+' do |f|
          f.write "Some Content\nWith a newline and trailing spaces    \n "
        end
        Netssh.new(a_host) do
          upload!(file_name, file_name)
          actual_file_contents = capture(:cat, file_name, strip: false)
        end.run
        assert_equal "Some Content\nWith a newline and trailing spaces    \n ", actual_file_contents
      end

      def test_upload_within
        file_name = SecureRandom.uuid
        file_contents = "Some Content"
        dir_name = SecureRandom.uuid
        actual_file_contents = ""
        Netssh.new(a_host) do |_host|
          within("/tmp") do
            execute :mkdir, "-p", dir_name
            within(dir_name) do
              upload!(StringIO.new(file_contents), file_name)
            end
          end
          actual_file_contents = capture(:cat, "/tmp/#{dir_name}/#{file_name}", strip: false)
        end.run
        assert_equal file_contents, actual_file_contents
      end

      def test_upload_string_io
        file_contents = ""
        Netssh.new(a_host) do |_host|
          file_name = File.join("/tmp", SecureRandom.uuid)
          upload!(StringIO.new('example_io'), file_name)
          file_contents = download!(file_name)
        end.run
        assert_equal "example_io", file_contents
      end

      def test_upload_large_file
        size      = 25
        fills     = SecureRandom.random_bytes(1024*1024)
        file_name = "/tmp/file-#{size}.txt"
        File.open(file_name, 'wb') do |f|
          (size).times {f.write(fills) }
        end
        file_contents = ""
        Netssh.new(a_host) do
          upload!(file_name, file_name)
          file_contents = download!(file_name)
        end.run
        assert_equal File.open(file_name, 'rb').read, file_contents
      end

      def test_upload_via_pathname
        file_contents = ""
        Netssh.new(a_host) do |_host|
          file_name = Pathname.new(File.join("/tmp", SecureRandom.uuid))
          upload!(StringIO.new('example_io'), file_name)
          file_contents = download!(file_name)
        end.run
        assert_equal "example_io", file_contents
      end
    end
  end
end
