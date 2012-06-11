module Deploy

  class CommandContext

    class With

      #
      # Wraps commands in a sub-shell and soft-exports the given env
      # variables to the shell (as a command prefix, without `export`)
      # the sub-shell contains the variables, such that the following
      # would print nothing:
      #
      # run("export TEST=first")
      # with({test: "Greeting"}) do
      #  puts capture_stdout("echo $TEST")
      # end
      # puts capture_stdout("echo $TEST")
      #
      # would output "Test", "First" - as the override only applies
      # to the given block.
      #
      # For more information about how this works, see:
      #
      #  * http://tldp.org/LDP/abs/html/subshells.html
      #
      # @author Lee Hambley
      #
      def initialize(*args, &block)
    
        raise ArgumentError, "Expected a block" unless block_given?
        raise ArgumentError, "Args must be Hash" unless args.first.is_a?(Hash)

        @block = block
        @environment = args.first

      end

      def execute
        sub_shell_pattern % @block.call.execute
      end

      private

        def sub_shell_pattern
          "( #{environment_string} %s )"
        end

        def environment_string
          @environment.collect do |key, value|
            "#{key.upcase}=\"#{value}\""
          end.join(" ")
        end

    end

  end

end
