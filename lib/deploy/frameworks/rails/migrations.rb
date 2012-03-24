module Deploy
  module Frameworks
    module Rails
      module Migration
        def update
          on(migration_servers, "migrate")
          super
        end
      end
    end
  end
end