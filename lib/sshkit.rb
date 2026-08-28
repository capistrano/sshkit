module SSHKit

  StandardError = Class.new(::StandardError)

  class << self

    def config=(configuration)
      @@config = configuration
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

  # Used for redaction of a certain argument
  module Redaction end

end

require_relative 'sshkit/all'
