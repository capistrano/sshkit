require 'thread'
require_relative 'deploy/all'

module Deploy

  class << self
    attr_accessor :config
  end

  def self.configure
    @@config ||= Configuration.new
    yield config
  end

  def self.config
    @@config ||= Configuration.new
  end

end
