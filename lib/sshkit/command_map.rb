module SSHKit
  class CommandMap
    class CommandHash
      def initialize(defaults = {})
        @storage = {}
        @defaults = defaults
      end

      def [](key)
        @storage[normalize_key(key)] ||= @defaults[key]
      end

      def []=(key, value)
        @storage[normalize_key(key)] = value
      end

      private

      def normalize_key(key)
        key.to_sym
      end
    end

    class PrefixProvider
      def initialize
        @storage = CommandHash.new
      end

      def [](command)
        @storage[command] ||= []
      end
    end

    TO_VALUE = ->(obj) { obj.respond_to?(:call) ? obj.call : obj }

    def initialize(value = nil)
      @map = CommandHash.new(value || defaults)
    end

    def [](command)
      if prefix[command].any?
        prefixes = prefix[command].map(&TO_VALUE)
        prefixes = prefixes.join(" ")

        "#{prefixes} #{command}"
      else
        TO_VALUE.(@map[command])
      end
    end

    def prefix
      @prefix ||= PrefixProvider.new
    end

    def []=(command, new_command)
      @map[command] = new_command
    end

    def clear
      @map = CommandHash.new(defaults)
    end

    def defaults
      Hash.new do |hash, command|
        if %w{if test time}.include? command.to_s
          hash[command] = command.to_s
        else
          hash[command] = "/usr/bin/env #{command}"
        end
      end
    end
  end
end
