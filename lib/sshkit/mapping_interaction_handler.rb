module SSHKit

  class MappingInteractionHandler

    def initialize(mapping)
      @mapping_proc = case mapping
        when Hash
          lambda do |server_output|
            first_matching_key_value = mapping.find { |k, _v| k === server_output }
            first_matching_key_value.nil? ? nil : first_matching_key_value.last
          end
        when Proc
          mapping
        else
          raise "Unsupported mapping type: #{mapping.class} - only Hash and Proc mappings are supported"
      end
    end

    def on_stdout(channel, data, command)
      on_data(channel, data, 'stdout')
    end

    def on_stderr(channel, data, command)
      on_data(channel, data, 'stderr')
    end

    private

    def on_data(channel, data, stream_name)
      output = SSHKit.config.output

      output.debug("Looking up response for #{stream_name} message #{data.inspect}")

      response_data = @mapping_proc.call(data)

      if response_data.nil?
        output.debug("Unable to find interaction handler mapping for #{stream_name}: #{data.inspect} so no response was sent")
      else
        output.debug("Sending response data")
        if channel.respond_to?(:send_data) # Net SSH Channel
          channel.send_data(response_data)
        elsif channel.respond_to?(:write) # Local IO
          channel.write(response_data)
        else
          raise "Unable to write response data to channel #{channel.inspect} - does not support 'send_data' or 'write'"
        end
      end
    end

  end

end