module Deploy

  class Configuration

    attr_writer :backend
    attr_accessor :output, :format, :runner

    def initialize
      @output  = $stdout
      @format  = :dot
      @runner  = :parallel
      @backend = :ssh
    end

    def backend
      (@backend.class == Class) ? @backend.new : @backend
    end

  end

end
