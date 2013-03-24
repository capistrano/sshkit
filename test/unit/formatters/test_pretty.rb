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
      assert_equal output.strip, " \e[31mFATAL\e[0m Test \n".strip
    end

    def test_logging_error
      pretty << SSHKit::LogMessage.new(Logger::ERROR, "Test")
      assert_equal output.strip, " \e[31mERROR\e[0m Test \n".strip
    end

    def test_logging_warn
      pretty << SSHKit::LogMessage.new(Logger::WARN, "Test")
      assert_equal output.strip, " \e[33mWARN\e[0m Test \n".strip
    end

    def test_logging_info
      pretty << SSHKit::LogMessage.new(Logger::INFO, "Test")
      assert_equal output.strip, " \e[34mINFO\e[0m Test \n".strip
    end

    def test_logging_debug
      pretty << SSHKit::LogMessage.new(Logger::DEBUG, "Test")
      assert_equal output.strip, " \e[30mDEBUG\e[0m Test \n".strip
    end

  end
end
