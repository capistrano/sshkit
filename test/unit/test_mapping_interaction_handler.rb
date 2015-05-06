require 'helper'

module SSHKit

  class TestMappingInteractionHandler < UnitTest
    def channel
      @channel ||= mock
    end

    def setup
      super
      @output = stub(debug: anything)
      SSHKit.config.output = @output
    end

    def test_calls_send_data_with_mapped_input_when_stdout_matches
      handler = MappingInteractionHandler.new('Server output' => "some input\n")

      channel.expects(:send_data).with("some input\n")

      handler.on_stdout(channel, 'Server output', nil)
    end

    def test_calls_send_data_with_mapped_input_when_stderr_matches
      channel.expects(:send_data).with("some input\n")

      MappingInteractionHandler.new('Server output' => "some input\n").on_stderr(channel, 'Server output', nil)
    end

    def test_raises_warning_if_server_output_is_not_matched
      @output.expects(:debug).with('Unable to find interaction handler mapping for stdout: "Server output\n" so no response was sent')

      MappingInteractionHandler.new({}).on_stdout(channel, "Server output\n", nil)
    end

    def test_does_not_warn_for_supports_mapping_to_nil
      MappingInteractionHandler.new({"Some output\n" => nil}).on_stdout(channel, "Some output\n", nil)
    end

    def test_supports_regex_keys
      channel.expects(:send_data).with("Input\n")

      MappingInteractionHandler.new({ /Some \w+ output\n/ => "Input\n"}).on_stdout(channel, "Some lovely output\n", nil)
    end

    def test_supports_lambda_mapping
      channel.expects(:send_data).with("GREAT Input\n")

      mapping = lambda do |server_output|
        case server_output
        when /Some (\w+) output\n/
          "#{$1.upcase} Input\n"
        end
      end

      MappingInteractionHandler.new(mapping).on_stdout(channel, "Some great output\n", nil)
    end


    def test_matches_keys_in_ofer
      interaction_handler = MappingInteractionHandler.new({
        "Specific output\n" => "Specific Input\n",
        /.*/ => "Default Input\n"
      })

      channel.expects(:send_data).with("Specific Input\n")
      interaction_handler.on_stdout(channel, "Specific output\n", nil)
    end

    def test_supports_default_mapping
      interaction_handler = MappingInteractionHandler.new({
        "Specific output\n" => "Specific Input\n",
        /.*/ => "Default Input\n"
      })

      channel.expects(:send_data).with("Specific Input\n")
      interaction_handler.on_stdout(channel, "Specific output\n", nil)
    end

    def test_raises_for_unsupported_mapping_type
      raised_error = assert_raises RuntimeError do
        MappingInteractionHandler.new(Object.new)
      end
      assert_equal('Unsupported mapping type: Object - only Hash and Proc mappings are supported', raised_error.message)
    end

    def test_raises_for_unsupported_channel_type
      handler = MappingInteractionHandler.new({"Some output\n" => "Whatever"})
      raised_error = assert_raises RuntimeError do
        handler.on_stdout(Object.new, "Some output\n", nil)
      end
      assert_match(/Unable to write response data to channel #<Object:.*> - does not support 'send_data' or 'write'/, raised_error.message)
    end
  end

end
