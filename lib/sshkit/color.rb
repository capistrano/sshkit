require 'colorize'

module SSHKit
  class Color
    def initialize(output, env=ENV)
      @output, @env = output, env
    end

    def colorize(obj, color, mode=nil)
      string = obj.to_s
      colorize? ? string.colorize(color: color, mode: mode) : string
    end

    def colorize?
      @env['SSHKIT_COLOR'] || (@output.respond_to?(:tty?) && @output.tty?)
    end
  end
end
