module Deploy
  module SCM
    module Git
      def check
        on(application_servers, "git fetch origin")
        super
      end
    
      def update
        on(application_servers, "git reset --hard master")
        super
      end
    end
  end
end