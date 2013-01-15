module Deploy

  module CommandHelper

    def rake(tasks=[])
      execute :rake, tasks
    end

    def make(tasks=[])
      execute :make, tasks
    end

    def execute(command, args=[])
      Command.new(command, args)
    end

    private

      def map(command)
        Deploy.config.command_map[command.to_sym]
      end

  end

  class Command

    attr_reader :command, :args

    def initialize(command, args=[])
      @command = command
      @args    = Array(args)
    end

    def to_s
      args.any? ? [command, *args].join(" ") : command.to_s
    end

  end

end
