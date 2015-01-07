require 'open3'
require 'fileutils'
module SSHKit

  module Backend
    class LocalPrinter < Printer
      def initialize(&block)
        @host = Host.new(:local) # just for logging
        @block = block
      end

      def run
        instance_exec(@host, &@block)
      end
    end
  end
end
