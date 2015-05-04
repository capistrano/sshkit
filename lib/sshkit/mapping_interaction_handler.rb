module SSHKit

  class MappingInteractionHandler

    def initialize(mapping, output=SSHKit.config.output)
      @mapping, @output = mapping, output
    end

    def on_stdout(channel, data, command)
      on_data(channel, data, 'stdout')
    end

    def on_stderr(channel, data, command)
      on_data(channel, data, 'stderr')
    end

    private

    def on_data(channel, data, stream_name)
      @output.debug("Looking up response for #{stream_name} message #{data.inspect}")

      @output.warn("Unable to find interaction handler mapping for #{stream_name}: #{data.inspect} so no response was sent") unless @mapping.key?(data)

      unless (response_data = @mapping[data]).nil?
        @output.debug("Sending #{response_data}")
        if channel.respond_to?(:send_data) # Net SSH Channel
          channel.send_data("#{response_data}\n")
        elsif channel.respond_to?(:write) # Local IO
          channel.write("#{response_data}\n")
        else
          raise 'Unable to write response data to channel - unrecognised channel type'
        end
      end
    end

  end

end