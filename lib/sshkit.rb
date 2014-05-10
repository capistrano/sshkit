module SSHKit

  StandardError = Class.new(::StandardError)

  class << self

    attr_accessor :config

    def capture_output(io, &block)
      original_io = config.output
      config.output = io
      config.output.extend(SSHKit::Utils::CaptureOutputMethods)
      yield
    ensure
      config.output = original_io
    end

    def configure
      @@config ||= Configuration.new
      yield config
    end

    def config
      @@config ||= Configuration.new
    end

    def reset_configuration!
      @@config = nil
    end

  end

end

require_relative 'sshkit/all'
