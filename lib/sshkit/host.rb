require 'ostruct'

module SSHKit

  UnparsableHostStringError = Class.new(SSHKit::StandardError)

  class Host

    attr_reader :hostname, :port, :username

    attr_accessor :password

    def initialize(host_string)

      suitable_parsers = [
        SimpleHostParser,
        HostWithPortParser,
        IPv6HostWithPortParser,
        HostWithUsernameParser,
        HostWithUsernameAndPortParser
      ].select do |p|
        p.suitable?(host_string)
      end

      if suitable_parsers.any?
        suitable_parsers.first.tap do |parser|
          @username, @hostname, @port = parser.new(host_string).attributes
        end
      else
        raise UnparsableHostStringError, "Cannot parse host string #{host_string}"
      end

    end

    def hash
      username.hash ^ hostname.hash ^ port.hash
    end

    def eql?(other_host)
      other_host.hash == hash
    end
    alias :== :eql?
    alias :equal? :eql?

    def to_key
      to_s.to_sym
    end

    def to_s
      sprintf("%s@%s:%d", username, hostname, port)
    end

    def properties
      @properties ||= OpenStruct.new
    end

  end

  # @private
  # :nodoc:
  class SimpleHostParser

    def self.suitable?(host_string)
      !host_string.match /[:|@]/
    end

    def initialize(host_string)
      @host_string = host_string
    end

    def username
      `whoami`.chomp
    end

    def port
      22
    end

    def hostname
      @host_string
    end

    def attributes
      [username, hostname, port]
    end

  end

  # @private
  # :nodoc:
  class HostWithPortParser < SimpleHostParser

    def self.suitable?(host_string)
      !host_string.match /[@|\[|\]]/
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
  class IPv6HostWithPortParser < SimpleHostParser

    def self.suitable?(host_string)
      host_string.match /[a-fA-F0-9:]+:\d+/
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

  # @private
  # :nodoc:
  class HostWithUsernameAndPortParser < SimpleHostParser
    def self.suitable?(host_string)
      host_string.match /@.*:\d+/
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

end
