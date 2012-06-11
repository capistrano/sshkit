module Deploy
  class CommandContext
    class In

      #
      # Initializes a new "In" (Directory) [CommandContext].
      #
      # Commands executed in this CommandContext will be wrapped inside a shell
      # conditional check using `man (1) test` to ensure the intended directory
      # exists before execution of the command; the case when the directory does
      # not exist is handled by an else-case, printing a warning and returning 
      # `man (1) false` under normal circumstances, this ensures that the task is
      # halted, and any appropriate callbacks, rollbacks, etc are honored.
      #
      # @author Lee Hambley
      #
      def initialize(*args, &block)
        
        unless block_given?
          raise ArgumentError, "Expected a block for CommandContext::In.new(). Called from #{caller.first}"
        end

        if args.length > 1
          warn "Warning too many arguments to CommandContext::In.new(). #{args.length - 1} ignored. Called from: #{caller.first}."
        end

        @block     = block
        @directory = args.first

      end

      #
      # Format the [CommandContext::In] ready to be passed to a shell
      # this executes the given block, and calls `execute` on the result
      # the block given may contain other compliant [CommandContext]s,
      # Commands and CommandResultModifiers
      # 
      # @author Lee Hambley
      # @return [String] a shell prepared command
      #
      def execute
        result = @block.call
        sprintf "%s %s %s", command_prefix, result.execute, command_suffix
      end

      #
      # The command prefix, made available predominently for testing
      # this method has little value outside of manually composing command
      # context strings for the test suite. One should use [execute] to more
      # properly use this class.
      #
      # @return [String] the shell command to prefix to the result of the given block
      #
      # @author Lee Hambley
      #
      def command_prefix
        prefix_pattern % @directory
      end

      #
      # The command suffix, made afailable predominantly for testing
      # this method has little value outside of manually composing command
      # context strings for the test suite. One should use [execute] to more 
      # properly use this class.
      #
      # @return [String] the shell command to  to the result of the given block
      #
      # @author Lee Hambley
      #
      def command_suffix
        "; else; echo \"#{error_message}\"; false; fi"
      end

      private

        def prefix_pattern
          "if [ -d \"%s\" ]; then"
        end

        def error_message
          "The directory \"#{@directory}\" does not exist, no operations may be performed in a non-existent directory." +
          "\n" +
          "This command will now terminate the operation by returning false (man (1) false)"
        end

    end
  end
end
