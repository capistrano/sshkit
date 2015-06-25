module SSHKit
  # Very basic support for ANSI color, so that we don't have to rely on
  # any external dependencies. This class handles colorizing strings, and
  # automatically disabling color if the underlying output is not a tty.
  #
  class Color
    COLOR_CODES = {
      :black   => 30,
      :red     => 31,
      :green   => 32,
      :yellow  => 33,
      :blue    => 34,
      :magenta => 35,
      :cyan    => 36,
      :white   => 37,
      :light_black   => 90,
      :light_red     => 91,
      :light_green   => 92,
      :light_yellow  => 93,
      :light_blue    => 94,
      :light_magenta => 95,
      :light_cyan    => 96,
      :light_white   => 97
    }.freeze

    def initialize(output, env=ENV)
      @output, @env = output, env
    end

    # Converts the given obj to string and surrounds in the appropriate ANSI
    # color escape sequence, based on the specified color and mode. The color
    # must be a symbol (see COLOR_CODES for a complete list).
    #
    # If the underlying output does not support ANSI color (see `colorize?),
    # the string will be not be colorized. Likewise if the specified color
    # symbol is unrecognized, the string will not be colorized.
    #
    # Note that the only mode currently support is :bold. All other values
    # will be silently ignored (i.e. treated the same as mode=nil).
    #
    def colorize(obj, color, mode=nil)
      string = obj.to_s
      return string unless colorize?
      return string unless COLOR_CODES.key?(color)

      result = mode == :bold ? "\e[1;" : "\e[0;"
      result << COLOR_CODES.fetch(color).to_s
      result << ";49m#{string}\e[0m"
    end

    # Returns `true` if the underlying output is a tty, or if the SSHKIT_COLOR
    # environment variable is set.
    #
    def colorize?
      @env['SSHKIT_COLOR'] || (@output.respond_to?(:tty?) && @output.tty?)
    end
  end
end
