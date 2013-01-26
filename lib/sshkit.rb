module SSHKit

  StandardError = Class.new(::StandardError)

  class << self
    attr_accessor :config
  end

  def self.capture_output(io, &block)
    original_io = config.output
    config.output = io
    yield
  ensure
    config.output = original_io
  end

  def self.configure
    @@config ||= Configuration.new
    yield config
  end

  def self.config
    @@config ||= Configuration.new
  end

  def self.reset_configuration!
    @@config = nil
  end

end

require_relative 'sshkit/all'
