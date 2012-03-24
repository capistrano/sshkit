module Deploy
  module ServerRoles
    ROLES = [:web, :application, :migration, :asset, :notification]

    def self.included(base)
      base.extend(ClassMethods)
    end

    ROLES.each do |role|
      class_eval %{
      def #{role}_servers
        self.class.#{role}_server_role
      end
      }
    end
    
    module ClassMethods

      ROLES.each do |role|
        class_eval %{
        def #{role}_servers(servers)
          @#{role}_server_role = Role.new(:#{role}_server, servers)
        end

        def #{role}_server_role
          @#{role}_server_role
        end
        }
      end
    end
  end
end

