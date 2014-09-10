require 'helper'
require 'sshkit'

module SSHKit
  class TestPretty < UnitTest

    def setup
      SSHKit.config.output_verbosity = Logger::DEBUG
    end

    def output
      @_output ||= String.new
    end

    def pretty
      @_pretty ||= SSHKit::Formatter::Pretty.new(output)
    end

    def teardown
      remove_instance_variable :@_pretty
      remove_instance_variable :@_output
      SSHKit.reset_configuration!
    end

    def test_logging_fatal
      pretty << SSHKit::LogMessage.new(Logger::FATAL, "Test")
      assert_equal output.strip, "\e[0;31;49mFATAL\e[0m Test"
    end

    def test_logging_error
      pretty << SSHKit::LogMessage.new(Logger::ERROR, "Test")
      assert_equal output.strip, "\e[0;31;49mERROR\e[0m Test"
    end

    def test_logging_warn
      pretty << SSHKit::LogMessage.new(Logger::WARN, "Test")
      assert_equal output.strip, "\e[0;33;49mWARN\e[0m Test".strip
    end

    def test_logging_info
      pretty << SSHKit::LogMessage.new(Logger::INFO, "Test")
      assert_equal output.strip, "\e[0;34;49mINFO\e[0m Test".strip
    end

    def test_logging_debug
      pretty << SSHKit::LogMessage.new(Logger::DEBUG, "Test")
      assert_equal output.strip, "\e[0;30;49mDEBUG\e[0m Test".strip
    end

  end
end
