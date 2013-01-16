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
        original_output.write "> Executing #{obj}\n"
      end
    end

    class TestPrinter < UnitTest

      def block_to_run
        lambda do |host|
          within '/opt/sites/example.com' do
            execute 'date'
            execute :ls, '-l', '/some/directory'
            with rails_env: :production do
              within :tmp do
                as :root do
                  execute :touch, 'restart.txt'
                end
              end
            end
          end
        end
      end

      def printer
        Printer.new(Host.new(:'example.com'), &block_to_run)
      end

      def test_simple_printing
        sio = ToSIoFormatter.new(StringIO.new)
        SSHKit.capture_output(sio) do
          printer.run
        end
        sio.rewind
        result = sio.read
        assert_equal <<-EOEXPECTED.unindent, result
          > Executing if test ! -d /opt/sites/example.com; then echo "Directory does not exist '/opt/sites/example.com'" 1>&2; false; fi
          > Executing cd /opt/sites/example.com && /usr/bin/env date
          > Executing cd /opt/sites/example.com && /usr/bin/env ls -l /some/directory
          > Executing if test ! -d /opt/sites/example.com/tmp; then echo "Directory does not exist '/opt/sites/example.com/tmp'" 1>&2; false; fi
          > Executing if ! sudo su root -c whoami > /dev/null; then echo "You cannot switch to user 'root' using sudo, please check the sudoers file" 1>&2; false; fi
          > Executing cd /opt/sites/example.com/tmp && ( RAILS_ENV=production sudo su root -c /usr/bin/env touch restart.txt )
        EOEXPECTED
      end

    end

  end

end
