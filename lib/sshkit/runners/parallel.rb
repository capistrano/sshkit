require 'thread'

module SSHKit

  module Runner

    class Parallel < Abstract
      def execute
        threads = []
        hosts.each do |host|
          threads << Thread.new(host) do |h|
            begin
              backend(h, &block).run
            rescue Exception => e
              e2 = ExecuteError.new e
              raise e2, "Exception while executing #{host.user ? "as #{host.user}@" : "on host "}#{host}: #{e.message}"
            end
          end
        end
        threads.map(&:join)
      end
    end

  end

end
