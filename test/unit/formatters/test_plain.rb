require 'helper'
require 'sshkit'

module SSHKit
  class TestPlain < UnitTest

    def setup
      SSHKit.config.output_verbosity = Logger::DEBUG
    end

    def output
      @_output ||= String.new
    end

    def plain
      @_plain ||= SSHKit::Formatter::Plain.new(output)
    end

    def teardown
      remove_instance_variable :@_plain
      remove_instance_variable :@_output
      SSHKit.reset_configuration!
    end

    def test_logging_fatal
      plain << SSHKit::LogMessage.new(Logger::FATAL, "Test")
      assert_equal output.strip, "[FATAL] Test \n".strip
    end

    def test_logging_error
      plain << SSHKit::LogMessage.new(Logger::ERROR, "Test")
      assert_equal output.strip, "[ERROR] Test \n".strip
    end

    def test_logging_warn
      plain << SSHKit::LogMessage.new(Logger::WARN, "Test")
      assert_equal output.strip, "[WARN] Test \n".strip
    end

    def test_logging_info
      plain << SSHKit::LogMessage.new(Logger::INFO, "Test")
      assert_equal output.strip, "[INFO] Test \n".strip
    end

    def test_logging_debug
      plain << SSHKit::LogMessage.new(Logger::DEBUG, "Test")
      assert_equal output.strip, "[DEBUG] Test \n".strip
    end

  end
end
