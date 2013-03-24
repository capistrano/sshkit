module SSHKit

  class LogMessage
    attr_reader :verbosity, :message
    def initialize(verbosity, message)
      @verbosity, @message = verbosity, message
    end
    def to_s
      @message.to_s.strip
    end
  end

end
