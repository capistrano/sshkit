require 'helper'

module Deploy

  class TestConfiguration < UnitTest

    def setup
      Deploy.config = nil
    end

    def test_output
      assert_equal $stdout, Deploy.config.output
      assert Deploy.config.output = $stderr
      assert_equal $stderr, Deploy.config.output
    end

    def test_format
      assert_equal :dot, Deploy.config.format
      assert Deploy.config.format = :pretty
      assert_equal :pretty, Deploy.config.format
    end

  end

end
