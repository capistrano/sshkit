module Deploy
  module DependencyManagers
    module Bundler
      def update
        on(application_servers, "bundle")
        super
      end
    end
  end
end