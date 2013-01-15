require 'shellwords'

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

    attr_reader :command, :args, :options

    def initialize(*args)
      @options = args.extract_options!
      @command = args.shift.to_sym
      @args    = args
    end

    def to_s
      if command.to_s.match("\n")
        String.new.tap do |cs|
          command.to_s.lines.each do |line|
            cs << line.strip
            cs << '; ' unless line == command.to_s.lines.to_a.last
          end
        end
      else
        String.new.tap do |cs|
          if options[:in]
            cs << sprintf("cd %s && ", options[:in])
          end
          if options[:env]
            cs << '( '
            options[:env].each do |k,v|
              cs << k.to_s.upcase
              cs << "="
              cs << v.to_s.shellescape
            end
            cs << ' '
          end
          cs << Deploy.config.command_map[command.to_sym]
          if args.any?
            cs << ' '
            cs << args.join(' ')
          end
          if options[:env]
            cs << ' )'
          end
          if options[:in]
            cs << '; cd -'
          end
        end
      end
    end

  end

end
