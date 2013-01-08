module Deploy

  module Backend

    class MockedCall
      attr_reader :action, :command, :args

      def initialize(action, command, args)
        @action, @command, @args = action, command, args
      end

      def to_return(rt={})
        rt = default_return.merge(rt)
      end

      private

      def default_return
        {stderr: nil, stdout: nil, status: 0}
      end

    end

    class MockBackend

      @mocked_calls = []

      def run(command, args=[])

      end

      def capture(command, args=[])
        raise "Boom not implemented yet"
      end

      def make(commands=[])

      end

      def rake(command=[])
        run("rake", *command, args)
      end

      def mock(action, command, args=[])
        MockedCall.new(action, command, args)
      end

    end

  end
end
