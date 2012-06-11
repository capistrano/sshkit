require 'helper'

module Deploy
  class TestCommandContext < UnitTest
  
    def test_returning_the_correct_sub_command_context_class_for_in

      context = CommandContext.new(:in, "/example/directory", &lambda { })

      expected_command_prefix = "if [ -d \"/example/directory\" ]; then "
      expected_command_suffix = "; fi"

      assert context.is_a? CommandContext::In

    end

    def test_returning_the_correct_sub_dommand_context_class_for_with

      context = CommandContext.new(:with, {env: :hash}, &lambda { })

      assert context.is_a? CommandContext::With
    
    end

  end
end
