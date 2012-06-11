require 'helper'

module Deploy

  class TestCommandContextWith < UnitTest

    def test_fails_when_not_passing_a_block
      assert_raises ArgumentError do
        CommandContext::With.new({test: :hash})
      end
    end

    def test_fails_if_not_passing_a_hash
      assert_raises ArgumentError do
        CommandContext::With.new({test: :hash})
      end
    end

    def test_execute_formats_the_command_correctly_in_context
      w = CommandContext::With.new({test: :env}, &lambda { stub(execute: :true )})
      expected_body = "( TEST=\"env\" true )"
      assert_equal expected_body, w.execute
    end

    # TODO: Shell Escaping (test for someone setting something with a quote)

  end

end
