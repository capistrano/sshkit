require 'thread'

module SSHKit

  module Runner

    class Parallel < Abstract
      def execute
        threads = hosts.map do |host|
          Thread.new(host) do |h|
            begin
              backend(h, &block).run
            rescue ::StandardError => e
              e2 = ExecuteError.new e
              raise e2, "Exception while executing #{host.user ? "as #{host.user}@" : "on host "}#{host}: #{e.message}"
            end
          end
        end

        wait_for_threads(threads)
      end

      private

      def wait_for_threads(threads)
        exception = nil

        threads.map do |t|
          begin
            t.join
          rescue ExecuteError => e
            exception ||= e
          end
        end

        raise exception if exception
      end
    end

  end

end
