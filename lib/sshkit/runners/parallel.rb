require 'thread'

module SSHKit

  module Runner

    class Parallel < Abstract
      def execute
        threads = []
        hosts.each do |host|
          threads << Thread.new(host) do |h|
            backend(host, &block).run
          end
        end
        threads.map(&:join)
      end
    end

  end

end
