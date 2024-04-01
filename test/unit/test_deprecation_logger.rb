require 'helper'

module SSHKit

  class TestDeprecationLogger < UnitTest

    def output
      @output ||= String.new
    end

    def logger
      @logger ||= DeprecationLogger.new(output)
    end

    def test_hides_duplicate_deprecation_warnings
      line_number = generate_warning
      generate_warning

      actual_lines = output.lines.to_a

      assert_equal(2, actual_lines.size)
      assert_equal "[Deprecated] Some message\n", actual_lines[0]
      assert_match %r{    \(Called from .*sshkit/test/unit/test_deprecation_logger.rb:#{line_number}:in .*generate_warning.\)\n}, actual_lines[1]
    end

    def test_handles_nil_output
      DeprecationLogger.new(nil).log('Some message')
    end

    private

    def generate_warning
      logger.log('Some message')
      __LINE__-1
    end
  end

end
