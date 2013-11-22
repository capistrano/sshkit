require 'helper'

module SSHKit

  module Backend

    class TestPrinter < UnitTest

      def block_to_run
        lambda do |host|
          execute :ls, '-l', '/some/directory'
        end
      end

      def backend
        @backend ||= Printer
      end

      def teardown
        @backend = nil
      end

      def printer
        Printer.new(Host.new(:'example.com'), &block_to_run)
      end

      def setup
        SSHKit.config.output_verbosity = :debug
      end

      def test_simple_printing
        result = StringIO.new
        SSHKit.capture_output(result) do
          printer.run
        end
        result.rewind
        assert_equal "/usr/bin/env ls -l /some/directory\n", result.read
      end

      def test_printer_respond_to_configure
        assert backend.respond_to?(:configure)
      end

      def test_printer_any_params_config
        backend.configure do |ssh|
          ssh.pty = true
          ssh.connection_timeout = 30
          ssh.ssh_options = {
              keys: %w(/home/user/.ssh/id_rsa),
              forward_agent: false,
              auth_methods: %w(publickey password)
          }
        end

        assert_equal 30, backend.config.connection_timeout
        assert_equal true, backend.config.pty

        assert_equal %w(/home/user/.ssh/id_rsa),  backend.config.ssh_options[:keys]
        assert_equal false,                       backend.config.ssh_options[:forward_agent]
        assert_equal %w(publickey password),      backend.config.ssh_options[:auth_methods]
      end

    end

  end

end
