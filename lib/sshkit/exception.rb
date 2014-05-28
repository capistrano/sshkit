module SSHKit

    module Runner

        class ExecuteError < StandardError
          attr_reader :cause

          def initialize cause
            @cause = cause
          end

          def backtrace
            @cause.backtrace
          end
 
          def backtrace_locations
            @cause.backtrace_locations
          end
        end
    end
end
