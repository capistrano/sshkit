require 'helper'

module Deploy
  class TestServerRoles < UnitTest 
    def test_correct_roles
      Deploy::ServerRoles.send(:remove_const, :ROLES)
      Deploy::ServerRoles.const_set(:ROLES, [:web])
      subject = Class.new
      subject.send(:include, Deploy::ServerRoles)
      subject.web_servers [1,2,3]
      assert_equal [1,2,3], subject.web_server_role.channels
    end
  end
end
