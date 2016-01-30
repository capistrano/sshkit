module SSHKit
  module Refinements
    refine Array do
      def extract_options!
        last.is_a?(::Hash) ? pop : {}
      end
    end

    refine Hash do
      def symbolize_keys
        inject({}) do |options, (key, value)|
          options[(key.to_sym rescue key) || key] = value
          options
        end
      end
      def symbolize_keys!
        self.replace(self.symbolize_keys)
      end
    end
  end
end
