module SSHKit

  class MappingInteractionHandler

    def initialize(mapping, log_level=nil)
      @log_level = log_level
      @mapping_proc = \
        case mapping
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

    def on_data(_command, stream_name, data, channel)
      log("Looking up response for #{stream_name} message #{data.inspect}")

      response_data = @mapping_proc.call(data)

      if response_data.nil?
        log("Unable to find interaction handler mapping for #{stream_name}: #{data.inspect} so no response was sent")
      else
        log("Sending #{response_data.inspect}")
        if channel.respond_to?(:send_data) # Net SSH Channel
          channel.send_data(response_data)
        elsif channel.respond_to?(:write) # Local IO
          channel.write(response_data)
        else
          raise "Unable to write response data to channel #{channel.inspect} - does not support 'send_data' or 'write'"
        end
      end
    end

    private

    def log(message)
      SSHKit.config.output.send(@log_level, message) unless @log_level.nil?
    end

  end

end
