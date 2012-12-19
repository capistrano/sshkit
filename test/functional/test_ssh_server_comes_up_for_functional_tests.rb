require 'helper'

module Deploy

  class TestHost < FunctionalTest

    def host
      @_host ||= Host.new('')
    end

    def test_that_it_works
      assert true
    end

    def test_step_in_here
      create_user_with_key(:codebeaker)
      keyfile = SSHUser.create(:codebeaker)
      assert File.exists?(keyfile)
    end

  end

end
