require 'English'
require 'strscan'
require 'mutex_m'
require 'net/ssh'
require 'net/scp'

module Net
  module SSH
    class Config
      class << self
        remove_method :default_files

        def default_files
          @@default_files + [File.join(Dir.pwd, '.ssh/config')]
        end
      end
    end
  end
end

module SSHKit

  module Backend

    class Netssh < Abstract
      class Configuration
        attr_accessor :connection_timeout, :pty
        attr_writer :ssh_options

        def ssh_options
          default_options.merge(@ssh_options ||= {})
        end

        private

        if Net::SSH::VALID_OPTIONS.include?(:known_hosts)
          def default_options
            @default_options ||= {known_hosts: SSHKit::Backend::Netssh::KnownHosts.new}
            assign_defaults
          end
        else
          def default_options
            @default_options ||= {}
            assign_defaults
          end
        end

        # Set default options early for ConnectionPool cache key
        def assign_defaults
          if Net::SSH.respond_to?(:assign_defaults)
            Net::SSH.assign_defaults(@default_options)
          else
            # net-ssh < 4.0.0 doesn't have assign_defaults
            unless @default_options.key?(:logger)
              require 'logger'
              @default_options[:logger] = ::Logger.new(STDERR)
              @default_options[:logger].level = ::Logger::FATAL
            end
          end
          @default_options
        end
      end

      def upload!(local, remote, options = {})
        summarizer = transfer_summarizer('Uploading')
        with_ssh do |ssh|
          ssh.scp.upload!(local, remote, options, &summarizer)
        end
      end

      def download!(remote, local=nil, options = {})
        summarizer = transfer_summarizer('Downloading')
        with_ssh do |ssh|
          ssh.scp.download!(remote, local, options, &summarizer)
        end
      end

      # Note that this pool must be explicitly closed before Ruby exits to
      # ensure the underlying IO objects are properly cleaned up. We register an
      # at_exit handler to do this automatically, as long as Ruby is exiting
      # cleanly (i.e. without an exception).
      @pool = SSHKit::Backend::ConnectionPool.new
      at_exit { @pool.close_connections if @pool && !$ERROR_INFO }

      class << self
        attr_accessor :pool

        def configure
          yield config
        end

        def config
          @config ||= Configuration.new
        end
      end

      private

      def transfer_summarizer(action)
        last_name = nil
        last_percentage = nil
        proc do |_ch, name, transferred, total|
          percentage = (transferred.to_f * 100 / total.to_f)
          unless percentage.nan?
            message = "#{action} #{name} #{percentage.round(2)}%"
            percentage_r = (percentage / 10).truncate * 10
            if percentage_r > 0 && (last_name != name || last_percentage != percentage_r)
              info message
              last_name = name
              last_percentage = percentage_r
            else
              debug message
            end
          else
            warn "Error calculating percentage #{transferred}/#{total}, " <<
              "is #{name} empty?"
          end
        end
      end

      def execute_command(cmd)
        output.log_command_start(cmd)
        cmd.started = true
        result = Struct.new(:exit_status).new(nil)
        with_ssh do |ssh|
          ssh.open_channel do |chan|
            chan.request_pty if Netssh.config.pty
            chan.exec(cmd.to_command) { set_handlers(chan, cmd, result) }
            chan.wait
          end
          ssh.loop
        end
        # Set exit_status and log the result upon completion
        if result.exit_status
          cmd.exit_status = result.exit_status
          output.log_command_exit(cmd)
        end
      end

      def set_handlers(channel, command, result)
        channel.on_data                   { |*args| handle_data          command, *args }
        channel.on_extended_data          { |*args| handle_extended_data command, *args }
        channel.on_request('exit-status') { |*args| handle_exit_status   result,  *args }
      end

      def handle_data(command, channel, data)
        command.on_stdout(channel, data)
        output.log_command_data(command, :stdout, data)
      end

      def handle_extended_data(command, channel, _type, data)
        command.on_stderr(channel, data)
        output.log_command_data(command, :stderr, data)
      end

      def handle_exit_status(result, _channel, data)
        result.exit_status = data.read_long
      end

      def with_ssh(&block)
        host.ssh_options = self.class.config.ssh_options.merge(host.ssh_options || {})
        self.class.pool.with(
          Net::SSH.method(:start),
          String(host.hostname),
          host.username,
          host.netssh_options,
          &block
        )
      end

    end
  end

end
