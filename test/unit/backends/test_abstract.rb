require 'helper'

module SSHKit

  module Backend

    class TestAbstract < UnitTest

      def test_run_executes_constructor_block_with_backend_as_context
        backend = example_backend do
          execute :ls, '-l', '/some/directory'
        end

        backend.expects(:execute).with(:ls, '-l', '/some/directory')

        backend.run
      end

      def test_abstract_backend_can_be_configured
        Abstract.configure do |config|
          config.some_option = 100
        end

        assert_equal 100, Abstract.config.some_option
      end

      def test_invoke_raises_no_method_error
        assert_raises NoMethodError do
          example_backend.invoke :echo
        end
      end

      private

      def example_backend(&block)
        block = block.nil? ? lambda {} : block
        Abstract.new(Host.new(:'example.com'), &block)
      end

    end

  end

end
