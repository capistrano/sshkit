require 'helper'

module SSHKit

  class TestDSL < UnitTest
    include SSHKit::DSL

    def test_dsl_on
      coordinator = mock
      Coordinator.stubs(:new).returns coordinator
      coordinator.expects(:each).at_least_once

      on('1.2.3.4')
    end

    def test_dsl_run_locally
      local_backend = mock
      Backend::Local.stubs(:new).returns local_backend
      local_backend.expects(:run).at_least_once

      run_locally
    end

  end

end
