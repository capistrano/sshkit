require 'helper'

module Deploy

  module Backend

    class ToSIoFormatter
      attr_reader :original_io
      def initialize(oio)
        @original_io = oio
      end
      def write(thing)
        original_io.write String(thing)
      end
    end

    class TestPrinter < UnitTest

      def test_simple_printing
        Deploy.config.output = ToSIoFormatter.new(Deploy.config.output)
        sio = StringIO.new
        Deploy.capture_output(sio) do
          Printer.new :'example.com' do |host|
            execute "date"
            rake "assets:precompile:all"
            within "/opt/sites/current" do
              execute :touch, 'tmp/restart.txt'
            end
          end
        end
        print sio.read
        # Should print:
        # $ date
        # $ /usr/bin/env rake assets:precompile:all
        # $ if [ ! -d "/opt/sites/current/" ]; then echo "Directory /opt/sites/current" doesn't exist on the host example.com 2>&1; fi
        # $ cd /opt/sites/current && touch tmp/restart.txt
      end

    end

  end

end
