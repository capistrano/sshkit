require 'helper'

module SSHKit

  module Backend

    class TestAbstract < UnitTest

      def test_make
        backend = ExampleBackend.new do
          make %w(some command)
        end

        backend.run

        assert_equal '/usr/bin/env make some command', backend.executed_command.to_command
      end

      def test_rake
        backend = ExampleBackend.new do
          rake %w(a command)
        end

        backend.run

        assert_equal '/usr/bin/env rake a command', backend.executed_command.to_command
      end

      def test_execute_creates_and_executes_command_with_default_options
        backend = ExampleBackend.new do
          execute :ls, '-l', '/some/directory'
        end

        backend.run

        assert_equal '/usr/bin/env ls -l /some/directory', backend.executed_command.to_command
        assert_equal(
          {:raise_on_non_zero_exit=>true, :run_in_background=>false, :in=>nil, :env=>nil, :host=>ExampleBackend.example_host, :user=>nil, :group=>nil},
          backend.executed_command.options
        )
      end

      def test_test_creates_and_executes_command_with_false_raise_on_non_zero_exit
        backend = ExampleBackend.new do
          test '[ -d /some/file ]'
        end

        backend.run

        assert_equal '[ -d /some/file ]', backend.executed_command.to_command
        assert_equal false, backend.executed_command.options[:raise_on_non_zero_exit], 'raise_on_non_zero_exit option'
      end

      def test_test_allows_to_override_verbosity
        backend = ExampleBackend.new do
          test 'echo output', {verbosity: Logger::INFO}
        end
        backend.run
        assert_equal(backend.executed_command.options[:verbosity], Logger::INFO)
      end

      def test_capture_creates_and_executes_command_and_returns_stripped_output
        output = nil
        backend = ExampleBackend.new do
          output = capture :cat, '/a/file'
        end
        backend.full_stdout = "Some stdout\n     "

        backend.run

        assert_equal '/usr/bin/env cat /a/file', backend.executed_command.to_command
        assert_equal 'Some stdout', output
      end

      def test_capture_supports_disabling_strip
        output = nil
        backend = ExampleBackend.new do
          output = capture :cat, '/a/file', :strip => false
        end
        backend.full_stdout = "Some stdout\n     "

        backend.run

        assert_equal '/usr/bin/env cat /a/file', backend.executed_command.to_command
        assert_equal "Some stdout\n     ", output
      end

      def test_within_properly_clears
        backend = ExampleBackend.new do
          within 'a' do
            execute :cat, 'file', :strip => false
          end

          execute :cat, 'file', :strip => false
        end

        backend.run

        assert_equal '/usr/bin/env cat file', backend.executed_command.to_command
      end

      def test_within_home
        backend = ExampleBackend.new do
          within '~/foo' do
            execute :cat, 'file', :strip => false
          end
        end

        backend.run

        assert_equal 'cd ~/foo && /usr/bin/env cat file', backend.executed_command.to_command
      end

      def test_background_logs_deprecation_warnings
        deprecation_out = ''
        SSHKit.config.deprecation_output = deprecation_out

        ExampleBackend.new do
          background :ls
        end.run

        lines = deprecation_out.lines.to_a

        assert_equal 2, lines.length

        assert_equal("[Deprecated] The background method is deprecated. Blame badly behaved pseudo-daemons!\n", lines[0])
        assert_match(/    \(Called from.*test_abstract.rb:\d+:in `block in test_background_logs_deprecation_warnings'\)\n/, lines[1])
      end

      def test_calling_abstract_with_undefined_execute_command_raises_exception
        abstract =  Abstract.new(ExampleBackend.example_host) do
          execute(:some_command)
        end

        assert_raises(SSHKit::Backend::MethodUnavailableError) do
          abstract.run
        end
      end

      def test_abstract_backend_can_be_configured
        Abstract.configure do |config|
          config.some_option = 100
        end

        assert_equal 100, Abstract.config.some_option
      end

      def test_invoke_raises_no_method_error
        assert_raises NoMethodError do
          ExampleBackend.new.invoke :echo
        end
      end

      def test_current_refers_to_currently_executing_backend
        backend = nil
        current = nil

        backend = ExampleBackend.new do
          backend = self
          current = SSHKit::Backend.current
        end
        backend.run

        assert_equal(backend, current)
      end

      def test_current_is_nil_outside_of_the_block
        backend = ExampleBackend.new do
          # nothing
        end
        backend.run

        assert_nil(SSHKit::Backend.current)
      end

      # Use a concrete ExampleBackend rather than a mock for improved assertion granularity
      class ExampleBackend < Abstract
        attr_writer :full_stdout
        attr_reader :executed_command

        def initialize(&block)
          block = block.nil? ? lambda {} : block
          super(ExampleBackend.example_host, &block)
          @full_stdout = nil
        end

        def execute_command(command)
          @executed_command = command
          command.on_stdout(nil, @full_stdout) unless @full_stdout.nil?
        end

        def ExampleBackend.example_host
          Host.new(:'example.com')
        end

      end

    end

  end

end
