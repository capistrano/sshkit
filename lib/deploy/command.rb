module Deploy
  class Command
    def initialize(command)
      @command = command
    end

    def execute
      @command
    end
  end
end