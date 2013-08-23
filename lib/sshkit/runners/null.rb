module SSHKit

  module Runner

    class Null < Abstract

      def execute
        SSHKit::Backend::Skipper.new(&block).run
      end
    end
  end
end
