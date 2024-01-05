require "net/scp"

module SSHKit
  module Backend
    class Netssh < Abstract
      class ScpTransfer
        def initialize(ssh, summarizer)
          @ssh = ssh
          @summarizer = summarizer
        end

        def upload!(local, remote, options)
          ssh.scp.upload!(local, remote, options, &summarizer)
        end

        def download!(remote, local, options)
          ssh.scp.download!(remote, local, options, &summarizer)
        end

        private

        attr_reader :ssh, :summarizer
      end
    end
  end
end
