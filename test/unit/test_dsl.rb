require 'helper'
require 'sshkit/dsl'

module SSHKit

  class TestDsl < UnitTest
    include SSHKit::DSL

    def setup
      SSHKit.config = nil
    end

    def test_run_locally
      SSHKit.config.expects(:local_backend).returns(Backend::Local)
      run_locally do
        # this gets executed
      end
    end
  end
end
