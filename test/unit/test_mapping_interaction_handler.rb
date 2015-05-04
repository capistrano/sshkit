require 'helper'

module SSHKit

  class TestMappingInteractionHandler < UnitTest
    def channel
      @channel ||= mock
    end

    def setup
      @output = stub(debug: anything)
      SSHKit.config.stubs(:output).returns(@output)
    end

    def test_calls_send_data_with_mapped_input_when_stdout_matches
      handler = MappingInteractionHandler.new('Server output' => "some input\n")

      channel.expects(:send_data).with("some input\n")

      handler.on_stdout(channel, 'Server output', nil)
    end

    def test_calls_send_data_with_mapped_input_when_stderr_matches
      handler = MappingInteractionHandler.new('Server output' => "some input\n")

      channel.expects(:send_data).with("some input\n")

      handler.on_stderr(channel, 'Server output', nil)
    end

    def test_raises_warning_if_server_output_is_not_matched
      handler = MappingInteractionHandler.new({})

      @output.expects(:warn).with('Unable to find interaction handler mapping for stdout: "Server output\n" so no response was sent')

      handler.on_stdout(channel, "Server output\n", nil)
    end
  end

end
