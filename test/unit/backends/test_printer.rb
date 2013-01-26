require 'helper'

module SSHKit

  module Backend

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
        result = String.new
        SSHKit.capture_output(result) do
          printer.run
        end
        assert_equal <<-EOEXPECTED.unindent, result
          if test ! -d /opt/sites/example.com; then echo "Directory does not exist '/opt/sites/example.com'" 1>&2; false; fi
          cd /opt/sites/example.com && /usr/bin/env date
          cd /opt/sites/example.com && /usr/bin/env ls -l /some/directory
          if test ! -d /opt/sites/example.com/tmp; then echo "Directory does not exist '/opt/sites/example.com/tmp'" 1>&2; false; fi
          if ! sudo su root -c whoami > /dev/null; then echo "You cannot switch to user 'root' using sudo, please check the sudoers file" 1>&2; false; fi
          cd /opt/sites/example.com/tmp && ( RAILS_ENV=production sudo su root -c \"/usr/bin/env touch restart.txt\" )
        EOEXPECTED
      end

    end

  end

end
