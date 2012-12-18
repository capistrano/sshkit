module Deploy
  class TestBackend
    def initialize(role,command)
      @role = role
      @command = Command.new(command)
    end

    def execute
      output = File.open('/dev/null', 'w+')
      @role.channels.each do |channel|
        output.write "#{@role.name}@#{channel}> #{@command.execute}"
      end
    ensure
      output.close
    end
  end
end
