require 'colorize'

module SSHKit
  class Color
    def initialize(io, env=ENV)
      @io, @env = io, env
    end

    def colorize(obj, color, mode=nil)
      string = obj.to_s
      colorize? ? string.colorize(color: color, mode: mode) : string
    end

    def colorize?
      @env['SSHKIT_COLOR'] || @io.tty?
    end
  end
end
