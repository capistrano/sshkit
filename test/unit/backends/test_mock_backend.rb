require 'helper'

module Deploy

  module Backend

    class TestMock < UnitTest

      def be
        @be = MockBackend.new
      end

      def teardown
        @be = nil
        @be.verify!
      end

      def test_mocking_a_run_call
        pending
        be.mock(:run, "date").to_return(stdout: ['Tue  8 Jan 2013 14:36:12 CET'])
        cr = be.run("date")
        assert cr.success?
        assert_equal 'Tue  8 Jan 2013 14:36:12 CET', cr.to_s
        assert_operator cr.run("date")
      end

    end

  end

end

