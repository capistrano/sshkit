module SSHKit
  class CommandMap
    class PrefixProvider
      def initialize
        @storage = {}
      end

      def [](command)
        @storage[command] ||= []

        @storage[command]
      end
    end

    def initialize(value = nil)
      @map = value || defaults
    end

    def [](command)
      if prefix[command].any?
        prefixes = prefix[command].join(" ")

        "#{prefixes} #{command}"
      else
        @map[command]
      end
    end

    def prefix
      @prefix ||= PrefixProvider.new
    end

    def []=(command, new_command)
      @map[command] = new_command
    end

    def clear
      @map = defaults
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
