module Deploy

  class Configuration

    attr_writer :backend, :command_map
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

    def command_map
      @command_map ||= Hash.new { |h,k| h[k] = k.to_s }
    end

  end

end
