require 'colorize'

class String
  COLORS = color_codes unless defined?(COLORS)
  MODES = mode_codes unless defined?(MODES)
end
