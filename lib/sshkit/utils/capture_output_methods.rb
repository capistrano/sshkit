module SSHKit
  module Utils
    module CaptureOutputMethods
      def <<(object)
        if object.is_a?(SSHKit::Command) || object.is_a?(SSHKit::LogMessage)
          super("#{object}\n")
        else
          super
        end
      end
    end
  end
end
