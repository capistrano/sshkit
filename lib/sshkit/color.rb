require 'colorize'
module Color
  STYLES = [String::COLORS, String::MODES].flat_map(&:keys)

  STYLES.each do |style|
    instance_eval %{
    def #{style}(string='')
      string = yield if block_given?
      $stdout.tty? ? string.colorize(:#{style}) : string
    end
    }
  end
end
