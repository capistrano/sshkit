module Deploy

  UnparsableHostStringError = Class.new(StandardError)

  class Host

    attr_reader :hostname, :port, :username

    def initialize(host_string)

      parsers = [SimpleHostParser, HostWithPortParser, IPv6HostWithPortParser, HostWithUsernameParser, HostWithUsernameAndPortParser].select do |p|
        p.suitable?(host_string)
      end

      if parsers.any?
        parsers.first.tap do |parser|
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

    def to_s
      sprintf("%s@%s:%d", username, hostname, port)
    end

  end

  class SimpleHostParser

    def self.suitable?(host_string)
      !host_string.match /[:|@]/
    end

    def initialize(host_string)
      @host_string = host_string
    end

    def username
      `whoami`
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
