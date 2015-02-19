module SSHKit

    module Runner

        class ExecuteError < StandardError
          attr_reader :cause

          def initialize cause
            @cause = cause
          end
        end
    end
end
