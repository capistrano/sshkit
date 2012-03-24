module Deploy
  module Notifiers
    module Twitter
      def start
        on(notification_servers, "deploy starting now")
        super
      end
  
      def finish
        on(notification_servers, "deploy complete")
        super
      end
    end
  end
end