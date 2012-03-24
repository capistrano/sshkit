require_relative '../lib/deploy'
module Deploy
  class MySuite < Suite
    include ApplicationServers::Unicorn
    include Frameworks::Rails::Migration
    include DependencyManagers::Bundler
    include SCM::Git
    include Notifiers::Twitter
  
    web_servers            %w{10.0.2.1}
    application_servers    %w{10.0.2.2 10.0.2.3}
    migration_servers      %w{10.0.2.4}
    asset_servers          %w{10.0.2.5}
    notification_servers   %w{127.0.0.1}
    
  end
end

deploy = Deploy::MySuite.new Deploy::TestBackend
deploy.run
