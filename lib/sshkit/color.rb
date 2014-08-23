require 'colorize'
module Color
  STYLES = [String::COLORS, String::MODES].flat_map(&:keys)

  STYLES.each do |style|
    instance_eval %{
    def #{style}(string='')
      string = yield if block_given?
      colorize? ? string.colorize(:#{style}) : string
    end

    def colorize?
      ENV['SSHKIT_COLOR'] || $stdout.tty?
    end
    }
  end
end
