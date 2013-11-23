require 'helper'
require 'securerandom'
require 'benchmark'

module SSHKit

  module Backend

    class TestNetssh < FunctionalTest

      def setup
        super
        SSHKit.config.output = SSHKit::Formatter::BlackHole.new($stdout)
      end

      def block_to_run
        lambda do |host|
          execute 'date'
          execute :ls, '-l', '/some/directory'
          with rails_env: :production do
            within '/tmp' do
              as :root do
                execute :touch, 'restart.txt'
              end
            end
          end
        end
      end

      def a_host
        VagrantWrapper.hosts["one"]
      end

      def printer
        Netssh.new(a_host, &block_to_run)
      end

      def simple_netssh
        SSHKit.capture_output(sio) do
          printer.run
        end
        sio.rewind
        result = sio.read
        assert_equal <<-EOEXPECTED.unindent, result
          if test ! -d /opt/sites/example.com; then echo "Directory does not exist '/opt/sites/example.com'" 2>&1; false; fi
          cd /opt/sites/example.com && /usr/bin/env date
          cd /opt/sites/example.com && /usr/bin/env ls -l /some/directory
          if test ! -d /opt/sites/example.com/tmp; then echo "Directory does not exist '/opt/sites/example.com/tmp'" 2>&1; false; fi
          if ! sudo su -u root whoami > /dev/null; then echo "You cannot switch to user 'root' using sudo, please check the sudoers file" 2>&1; false; fi
          cd /opt/sites/example.com/tmp && ( RAILS_ENV=production ( sudo su -u root /usr/bin/env touch restart.txt ) )
        EOEXPECTED
      end

      def test_capture
        File.open('/dev/null', 'w') do |dnull|
          SSHKit.capture_output(dnull) do
            captured_command_result = ""
            Netssh.new(a_host) do |host|
              captured_command_result = capture(:uname)
            end.run
            assert_equal "Linux", captured_command_result
          end
        end
      end

      def test_execute_raises_on_non_zero_exit_status_and_captures_stdout_and_stderr
        err = assert_raises SSHKit::Command::Failed do
          Netssh.new(a_host) do |host|
            execute :echo, "'Test capturing stderr' 1>&2; false"
          end.run
        end
        assert_equal "echo stdout: Nothing written\necho stderr: Test capturing stderr\n", err.message
      end

      def test_test_does_not_raise_on_non_zero_exit_status
        Netssh.new(a_host) do |host|
          test :false
        end.run
      end

      def test_backgrounding_a_process
        #SSHKit.config.output = SSHKit::Formatter::Pretty.new($stdout)
        process_list = ""
        time = Benchmark.measure do
          Netssh.new(a_host) do
            background :sleep, 5
          end.run
          Netssh.new(a_host) do
            process_list = capture :ps, "aux | grep sleep | grep -v grep; true"
          end.run
        end
        assert_operator time.real, :<, 1
        assert_match "sleep 5", process_list
      end

      def test_upload_file
        file_contents = ""
        file_name = File.join("/tmp", SecureRandom.uuid)
        File.open file_name, 'w+' do |f|
          f.write 'example_file'
        end
        Netssh.new(a_host) do
          upload!(file_name, file_name)
          file_contents = capture(:cat, file_name)
        end.run
        assert_equal "example_file", file_contents
      end

      def test_upload_string_io
        file_contents = ""
        Netssh.new(a_host) do |host|
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
        File.open(file_name, 'w') do |f|
          (size).times {f.write(fills) }
        end
        file_contents = ""
        Netssh.new(a_host) do
          upload!(file_name, file_name)
          file_contents = download!(file_name)
        end.run
        assert_equal File.open(file_name).read, file_contents
      end

    end

  end

end
