module Deploy
  class Dispatch
    def initialize
      @queue = Queue.new
      @consumer ||= Thread.new { execute_commands }
    end

    def <<(cmd)
      @queue << cmd
    end

    def consumer
      @consumer
    end

    def execute_commands
      loop do
        @queue.pop.execute
        exit if @queue.empty?
      end
    end

    def work
      consumer.join
    end
  end
end