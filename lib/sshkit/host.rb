require 'ostruct'

module SSHKit

  UnparsableHostStringError = Class.new(SSHKit::StandardError)

  class Host

    attr_accessor :password, :hostname, :port, :user, :ssh_options

    def key=(new_key)
      @keys = [new_key]
    end

    def keys=(new_keys)
      @keys = new_keys
    end

    def keys
      Array(@keys)
    end

    def initialize(host_string_or_options_hash)
      @keys  = []
      @local = false

      if host_string_or_options_hash == :local
        @local = true
        @hostname = "localhost"
        @user = ENV['USER'] || ENV['LOGNAME'] || ENV['USERNAME']
      elsif !host_string_or_options_hash.is_a?(Hash)
        @user, @hostname, @port = first_suitable_parser(host_string_or_options_hash).attributes
      else
        host_string_or_options_hash.each do |key, value|
          if self.respond_to?("#{key}=")
            send("#{key}=", value)
          else
            raise ArgumentError, "Unknown host property #{key}"
          end
        end
      end
    end

    def local?
      @local
    end

    def hash
      user.hash ^ hostname.hash ^ port.hash
    end

    def username
      user
    end

    def eql?(other_host)
      other_host.hash == hash
    end
    alias :== :eql?
    alias :equal? :eql?

    def to_s
      hostname
    end

    def netssh_options
      {}.tap do |sho|
        sho[:keys]          = keys     if keys.any?
        sho[:port]          = port     if port
        sho[:user]          = user     if user
        sho[:password]      = password if password
        sho[:forward_agent] = true
      end
      .merge(ssh_options || {})
    end

    def properties
      @properties ||= OpenStruct.new
    end

    def first_suitable_parser(host)
      parser = PARSERS.find{|p| p.suitable?(host) }
      fail UnparsableHostStringError, "Cannot parse host string #{host}" if parser.nil?
      parser.new(host)
    end
  end

  # @private
  # :nodoc:
  class SimpleHostParser

    def self.suitable?(host_string)
      !host_string.match(/:|@/)
    end

    def initialize(host_string)
      @host_string = host_string
    end

    def username

    end

    def port

    end

    def hostname
      @host_string
    end

    def attributes
      [username, hostname, port]
    end

  end

  class HostWithPortParser < SimpleHostParser

    def self.suitable?(host_string)
      !host_string.match(/@|\[|\]/)
    end

    def port
      @host_string.split(':').last.to_i
    end

    def hostname
      @host_string.split(':').first
    end

  end

  # @private
  # :nodoc:
  class HostWithUsernameAndPortParser < SimpleHostParser
    def self.suitable?(host_string)
      host_string.match(/@.*:\d+/)
    end
    def username
      @host_string.split(/:|@/)[0]
    end
    def hostname
      @host_string.split(/:|@/)[1]
    end
    def port
      @host_string.split(/:|@/)[2].to_i
    end
  end

  # @private
  # :nodoc:
  class IPv6HostWithPortParser < SimpleHostParser

    def self.suitable?(host_string)
      host_string.match(/[a-fA-F0-9:]+:\d+/)
    end

    def port
      @host_string.split(':').last.to_i
    end

    def hostname
      @host_string.gsub!(/\[|\]/, '')
      @host_string.split(':')[0..-2].join(':')
    end

  end

  # @private
  # :nodoc:
  class HostWithUsernameParser < SimpleHostParser
    def self.suitable?(host_string)
      host_string.match(/@/) && !host_string.match(/\:/)
    end
    def username
      @host_string.split('@').first
    end
    def hostname
      @host_string.split('@').last
    end
  end

  PARSERS = [
    SimpleHostParser,
    HostWithPortParser,
    HostWithUsernameAndPortParser,
    IPv6HostWithPortParser,
    HostWithUsernameParser,
  ].freeze

end
