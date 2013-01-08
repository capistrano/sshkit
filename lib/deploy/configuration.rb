module Deploy

  class Configuration

    attr_accessor :output, :format

    def initialize
      @output = $stdout
      @format = :dot
    end

  end

end
