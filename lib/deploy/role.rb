module Deploy
  class Role
    def initialize(name, channels)
      @name = name
      @channels = channels
    end

    def name
      @name
    end
 
    def channels
      @channels
    end
  end
end