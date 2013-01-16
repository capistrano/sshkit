module SSHKit

  module Formatter

    class BlackHole < Abstract

      def write(obj)
        # Nothing, nothing to do
      end
      alias :<< :write

    end

  end

end
