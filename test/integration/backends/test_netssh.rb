require 'helper'

module SSHKit

  module Backend

    class ToSIoFormatter < StringIO
      extend Forwardable
      attr_reader :original_output
      def_delegators :@original_output, :read, :rewind
      def initialize(oio)
        @original_output = oio
      end
      def write(obj)
        warn "What: #{obj.to_hash}"
        original_output.write "> Executing #{obj}\n"
      end
    end

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
        vm_hosts.first
      end

      def printer
        Netssh.new(a_host, &block_to_run)
      end

      def simple_netssh
        sio = ToSIoFormatter.new(StringIO.new)
        SSHKit.capture_output(sio) do
          printer.run
        end
        sio.rewind
        result = sio.read
        assert_equal <<-EOEXPECTED.unindent, result
          > Executing if test ! -d /opt/sites/example.com; then echo "Directory does not exist '/opt/sites/example.com'" 2>&1; false; fi
          > Executing cd /opt/sites/example.com && /usr/bin/env date
          > Executing cd /opt/sites/example.com && /usr/bin/env ls -l /some/directory
          > Executing if test ! -d /opt/sites/example.com/tmp; then echo "Directory does not exist '/opt/sites/example.com/tmp'" 2>&1; false; fi
          > Executing if ! sudo su -u root whoami > /dev/null; then echo "You cannot switch to user 'root' using sudo, please check the sudoers file" 2>&1; false; fi
          > Executing cd /opt/sites/example.com/tmp && ( RAILS_ENV=production ( sudo su -u root /usr/bin/env touch restart.txt ) )
        EOEXPECTED
      end

      def test_capture
        File.open('/dev/null', 'w') do |dnull|
          SSHKit.capture_output(dnull) do
            captured_command_result = ""
            Netssh.new(a_host) do |host|
              captured_command_result = capture(:hostname)
            end.run
            assert_equal "lucid32", captured_command_result
          end
        end
      end

      def test_execute_raises_on_non_zero_exit_status_and_captures_stderr
        err = assert_raises SSHKit::Command::Failed do
          Netssh.new(a_host) do |host|
            execute :echo, "'Test capturing stderr' 1>&2; false"
          end.run
        end
        assert_equal "Test capturing stderr", err.message
      end

      def test_test_does_not_raise_on_non_zero_exit_status
        Netssh.new(a_host) do |host|
          test :false
        end.run
      end

    end

  end

end
