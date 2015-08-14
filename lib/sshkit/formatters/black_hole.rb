module SSHKit

  module Formatter

    class BlackHole < Abstract

      def write(_obj)
        # Nothing, nothing to do
      end

    end

  end

end
