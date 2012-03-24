require 'helper'

module Deploy
  class TestDispatch < UnitTest
    def test_new_dispatch_has_a_queue
      Queue.expects(:new)
      Dispatch.new
    end

    def test_new_dispatch_has_a_thread
      Thread.expects(:new)
      Dispatch.new
    end

    def test_responds_to_append
      dispatch = Dispatch.new
      assert_respond_to dispatch, :<<
    end

    def test_consumer_is_readble
      consumer = mock
      Thread.expects(:new).returns(consumer)
      dispatch = Dispatch.new
      assert_equal consumer, dispatch.consumer
    end

    def test_dispatch_can_work
      consumer = mock
      Thread.expects(:new).returns(consumer)
      consumer.expects(:join)
      Dispatch.new.work
    end
  end
end