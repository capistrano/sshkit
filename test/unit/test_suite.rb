require 'helper'

module Deploy
  class TestSuite < UnitTest

    def setup
      @backend = TestBackend
    end
    
    def test_new_suite_has_a_backend
      Dispatch.expects(:new)
      Suite.new(@backend)
    end

    def test_new_suite_enqueues
      Suite.any_instance.expects(:stages).returns([:start, :finish])
      Suite.any_instance.expects(:start)
      Suite.any_instance.expects(:finish) 
      suite = Suite.new(@backend)
    end

    def test_on_adds_a_backend_command
      dispatch,backend = mock, mock
      Dispatch.expects(:new).returns(dispatch)
      @backend.expects(:new).with(:app,:test).
        returns(backend)
      dispatch.expects(:<<).with(backend)
      Suite.new(@backend).on(:app, :test)
    end

    def test_run_delegates_to_dispatch
      dispatch = mock
      Dispatch.expects(:new).returns(dispatch)
      dispatch.expects(:work)
      Suite.new(@backend).run
    end
  end
end