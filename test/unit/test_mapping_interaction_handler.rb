require 'helper'

module SSHKit

  class TestMappingInteractionHandler < UnitTest
    def channel
      @channel ||= mock
    end

    def setup
      super
      @output = stub()
      SSHKit.config.output = @output
    end

    def test_calls_send_data_with_mapped_input_when_stdout_matches
      handler = MappingInteractionHandler.new('Server output' => "some input\n")
      channel.expects(:send_data).with("some input\n")
      handler.on_data(nil, :stdout, 'Server output', channel)
    end

    def test_calls_send_data_with_mapped_input_when_stderr_matches
      handler = MappingInteractionHandler.new('Server output' => "some input\n")
      channel.expects(:send_data).with("some input\n")
      handler.on_data(nil, :stderr, 'Server output', channel)
    end

    def test_logs_unmatched_interaction_if_constructed_with_a_log_level
      @output.expects(:debug).with('Looking up response for stdout message "Server output\n"')
      @output.expects(:debug).with('Unable to find interaction handler mapping for stdout: "Server output\n" so no response was sent')

      MappingInteractionHandler.new({}, :debug).on_data(nil, :stdout, "Server output\n", channel)
    end

    def test_logs_matched_interaction_if_constructed_with_a_log_level
      handler = MappingInteractionHandler.new({"Server output\n" => "Some input\n"}, :debug)

      channel.stubs(:send_data)
      @output.expects(:debug).with('Looking up response for stdout message "Server output\n"')
      @output.expects(:debug).with('Sending "Some input\n"')

      handler.on_data(nil, :stdout, "Server output\n", channel)
    end

    def test_supports_regex_keys
      handler = MappingInteractionHandler.new({/Some \w+ output\n/ => "Input\n"})
      channel.expects(:send_data).with("Input\n")
      handler.on_data(nil, :stdout, "Some lovely output\n", channel)
    end

    def test_supports_lambda_mapping
      channel.expects(:send_data).with("GREAT Input\n")

      mapping = lambda do |server_output|
        case server_output
        when /Some (\w+) output\n/
          "#{$1.upcase} Input\n"
        end
      end

      MappingInteractionHandler.new(mapping).on_data(nil, :stdout, "Some great output\n", channel)
    end


    def test_matches_keys_in_ofer
      interaction_handler = MappingInteractionHandler.new({
        "Specific output\n" => "Specific Input\n",
        /.*/ => "Default Input\n"
      })

      channel.expects(:send_data).with("Specific Input\n")
      interaction_handler.on_data(nil, :stdout, "Specific output\n", channel)
    end

    def test_supports_default_mapping
      interaction_handler = MappingInteractionHandler.new({
        "Specific output\n" => "Specific Input\n",
        /.*/ => "Default Input\n"
      })

      channel.expects(:send_data).with("Specific Input\n")
      interaction_handler.on_data(nil, :stdout, "Specific output\n", channel)
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
        handler.on_data(nil, :stdout, "Some output\n", Object.new)
      end
      assert_match(/Unable to write response data to channel #<Object:.*> - does not support 'send_data' or 'write'/, raised_error.message)
    end
  end

end
