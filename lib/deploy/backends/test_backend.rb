module Deploy
  class TestBackend
    def initialize(role,command)
      @role = role
      @command = Command.new(command)
    end

    def execute
      @role.channels.each do |channel|
        puts "#{@role.name}@#{channel}> #{@command.execute}"
      end
    end
  end
end
