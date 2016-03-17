module SSHKit

  StandardError = Class.new(::StandardError)

  class << self

    attr_writer :config

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
