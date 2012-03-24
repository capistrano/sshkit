module Deploy
  module ApplicationServers
    module Unicorn
      def update
        on(web_servers, "restart")
        super
      end
    end
  end
end