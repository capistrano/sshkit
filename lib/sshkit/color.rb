require 'colorize'

module Color
  String::COLORS.each_pair do |color, _|
    instance_eval <<-RUBY, __FILE__, __LINE__
      def #{color}(string = '')
        string = yield if block_given?
        colorize? ? string.colorize(:color => :#{color}) : string
      end
    RUBY
  end

  String::MODES.each_pair do |mode, _|
    instance_eval <<-RUBY, __FILE__, __LINE__
      def #{mode}(string = '')
        string = yield if block_given?
        colorize? ? string.colorize(:mode => :#{mode}) : string
      end
    RUBY
  end

  class << self
    def colorize?
      ENV['SSHKIT_COLOR'] || $stdout.tty?
    end
  end
end
