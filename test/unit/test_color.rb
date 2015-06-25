require 'helper'
require 'sshkit'

module SSHKit
  class TestColor < UnitTest

    def test_colorize_when_tty_available
      color = SSHKit::Color.new(stub(tty?: true), {})
      assert_equal "\e[1;32;49mhi\e[0m", color.colorize('hi', :green, :bold)
    end

    def test_colorize_when_SSHKIT_COLOR_present
      color = SSHKit::Color.new(stub(tty?: false), {'SSHKIT_COLOR' => 'a'})
      assert_equal "\e[0;31;49mhi\e[0m", color.colorize('hi', :red)
    end

    def test_does_not_colorize_when_no_tty_and_SSHKIT_COLOR_not_present
      color = SSHKit::Color.new(stub(tty?: false), {})
      assert_equal 'hi', color.colorize('hi', :red)
    end

    # The output parameter may not define the tty method eg if it is a Logger.
    # In this case we assume showing colors would not be supported
    # https://github.com/capistrano/sshkit/pull/246#issuecomment-100358122
    def test_does_not_colorize_when_tty_method_not_defined_and_SSHKIT_COLOR_not_present
      color = SSHKit::Color.new(stub(), {})
      assert_equal 'hi', color.colorize('hi', :red)
    end

    def test_colorize_colors
      color = SSHKit::Color.new(stub(tty?: true), {})
      assert_equal "\e[0;30;49mhi\e[0m", color.colorize('hi', :black)
      assert_equal "\e[0;31;49mhi\e[0m", color.colorize('hi', :red)
      assert_equal "\e[0;32;49mhi\e[0m", color.colorize('hi', :green)
      assert_equal "\e[0;33;49mhi\e[0m", color.colorize('hi', :yellow)
      assert_equal "\e[0;34;49mhi\e[0m", color.colorize('hi', :blue)
      assert_equal "\e[0;35;49mhi\e[0m", color.colorize('hi', :magenta)
      assert_equal "\e[0;36;49mhi\e[0m", color.colorize('hi', :cyan)
      assert_equal "\e[0;37;49mhi\e[0m", color.colorize('hi', :white)
      assert_equal "\e[0;90;49mhi\e[0m", color.colorize('hi', :light_black)
      assert_equal "\e[0;91;49mhi\e[0m", color.colorize('hi', :light_red)
      assert_equal "\e[0;92;49mhi\e[0m", color.colorize('hi', :light_green)
      assert_equal "\e[0;93;49mhi\e[0m", color.colorize('hi', :light_yellow)
      assert_equal "\e[0;94;49mhi\e[0m", color.colorize('hi', :light_blue)
      assert_equal "\e[0;95;49mhi\e[0m", color.colorize('hi', :light_magenta)
      assert_equal "\e[0;96;49mhi\e[0m", color.colorize('hi', :light_cyan)
      assert_equal "\e[0;97;49mhi\e[0m", color.colorize('hi', :light_white)
    end

    def test_colorize_bold_colors
      color = SSHKit::Color.new(stub(tty?: true), {})
      assert_equal "\e[1;30;49mhi\e[0m", color.colorize('hi', :black, :bold)
      assert_equal "\e[1;31;49mhi\e[0m", color.colorize('hi', :red, :bold)
      assert_equal "\e[1;32;49mhi\e[0m", color.colorize('hi', :green, :bold)
      assert_equal "\e[1;33;49mhi\e[0m", color.colorize('hi', :yellow, :bold)
      assert_equal "\e[1;34;49mhi\e[0m", color.colorize('hi', :blue, :bold)
      assert_equal "\e[1;35;49mhi\e[0m", color.colorize('hi', :magenta, :bold)
      assert_equal "\e[1;36;49mhi\e[0m", color.colorize('hi', :cyan, :bold)
      assert_equal "\e[1;37;49mhi\e[0m", color.colorize('hi', :white, :bold)
      assert_equal "\e[1;90;49mhi\e[0m", color.colorize('hi', :light_black, :bold)
      assert_equal "\e[1;91;49mhi\e[0m", color.colorize('hi', :light_red, :bold)
      assert_equal "\e[1;92;49mhi\e[0m", color.colorize('hi', :light_green, :bold)
      assert_equal "\e[1;93;49mhi\e[0m", color.colorize('hi', :light_yellow, :bold)
      assert_equal "\e[1;94;49mhi\e[0m", color.colorize('hi', :light_blue, :bold)
      assert_equal "\e[1;95;49mhi\e[0m", color.colorize('hi', :light_magenta, :bold)
      assert_equal "\e[1;96;49mhi\e[0m", color.colorize('hi', :light_cyan, :bold)
      assert_equal "\e[1;97;49mhi\e[0m", color.colorize('hi', :light_white, :bold)
    end

    def test_ignores_unrecognized_color
      color = SSHKit::Color.new(stub(tty?: true), {})
      assert_equal 'hi', color.colorize('hi', :tangerine)
    end

    def test_ignores_unrecognized_mode
      color = SSHKit::Color.new(stub(tty?: true), {})
      assert_equal "\e[0;31;49mhi\e[0m", color.colorize('hi', :red, :underline)
    end
  end
end
