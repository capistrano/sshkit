require 'helper'

module Deploy
  class TestCommandContextIn < UnitTest
  
    def test_fails_when_not_passing_a_block
      assert_raises ArgumentError, "wrong number of nargs" do
        CommandContext::In.new("/tmp")
      end
    end

    def test_warning_if_passing_too_many_args
      out, err = capture_io do
        CommandContext::In.new(["too"], ["many"], ["arguments"], &lambda { })
      end
      assert_match /too many/, err
      assert_match /2 ignored/, err
      assert_match Regexp.new(__FILE__), err
    end


    def test_returning_the_correct_sub_command_context

      in_context = CommandContext::In.new("/example/directory", &lambda { })

      expected_command_prefix = "if [ -d \"/example/directory\" ]; then"
      expected_command_suffix = /false; fi/

      assert_equal expected_command_prefix, in_context.command_prefix
      assert_match expected_command_suffix, in_context.command_suffix

    end

    def test_being_executable_conforming_to_the_command_api_and_being_interchangeable
      
      stub_command = stub(execute: "STUB COMMAND")

      in_context = CommandContext::In.new("/example/dir", &lambda { stub_command })

      expected_command = "if [ -d \"/example/dir\" ]; then STUB COMMAND ; else; echo \"The directory \"/example/dir\" does not exist, no operations may be performed in a non-existent directory.
This command will now terminate the operation by returning false (man (1) false)\"; false; fi"

      assert_equal expected_command, in_context.execute

    end

    def test_nesting_in_context_in_context_longhand

      stub_command = stub(execute: "STUB COMMAND")

      c = CommandContext::In.new("/var") do
        CommandContext::In.new("/log") do
          stub_command
        end
      end

      expected_body = "if [ -d \"/var\" ]; then if [ -d \"/log\" ]; then STUB COMMAND ; else; echo \"The directory \"/log\" does not exist, no operations may be performed in a non-existent directory.
This command will now terminate the operation by returning false (man (1) false)\"; false; fi ; else; echo \"The directory \"/var\" does not exist, no operations may be performed in a non-existent directory.
This command will now terminate the operation by returning false (man (1) false)\"; false; fi"

      assert_equal expected_body, c.execute

    end

  end
end

