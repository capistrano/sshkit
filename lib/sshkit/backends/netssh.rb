require 'English'
require 'strscan'
require 'net/ssh'

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
      def self.assert_valid_transfer_method!(method)
        return if [:scp, :sftp].include?(method)

        raise ArgumentError, "#{method.inspect} is not a valid transfer method. Supported methods are :scp, :sftp."
      end

      class Configuration
        attr_accessor :connection_timeout, :pty
        attr_reader :transfer_method
        attr_writer :ssh_options

        def initialize
          self.transfer_method = :scp
        end

        def transfer_method=(method)
          Netssh.assert_valid_transfer_method!(method)

          @transfer_method = method
        end

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
        summarizer = transfer_summarizer('Uploading', options)
        remote = File.join(pwd_path, remote) unless remote.to_s.start_with?("/") || pwd_path.nil?
        with_transfer(summarizer) do |transfer|
          transfer.upload!(local, remote, options)
        end
      end

      def download!(remote, local=nil, options = {})
        summarizer = transfer_summarizer('Downloading', options)
        remote = File.join(pwd_path, remote) unless remote.to_s.start_with?("/") || pwd_path.nil?
        with_transfer(summarizer) do |transfer|
          transfer.download!(remote, local, options)
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

      def transfer_summarizer(action, options = {})
        log_percent = options[:log_percent] || 10
        log_percent = 100 if log_percent <= 0
        last_name = nil
        last_percentage = nil
        proc do |_ch, name, transferred, total|
          percentage = (transferred.to_f * 100 / total.to_f)
          unless percentage.nan? || percentage.infinite?
            message = "#{action} #{name} #{percentage.round(2)}%"
            percentage_r = (percentage / log_percent).truncate * log_percent
            if percentage_r > 0 && (last_name != name || last_percentage != percentage_r)
              verbosity = (options[:verbosity] || :INFO).downcase # TODO: ideally reuse command.rb logic
              public_send verbosity, message
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
        output.log_command_start(cmd.with_redaction)
        cmd.started = true
        exit_status = nil
        with_ssh do |ssh|
          ssh.open_channel do |chan|
            chan.request_pty if Netssh.config.pty
            chan.exec cmd.to_command do |_ch, _success|
              chan.on_data do |ch, data|
                cmd.on_stdout(ch, data)
                output.log_command_data(cmd, :stdout, data)
              end
              chan.on_extended_data do |ch, _type, data|
                cmd.on_stderr(ch, data)
                output.log_command_data(cmd, :stderr, data)
              end
              chan.on_request("exit-status") do |_ch, data|
                exit_status = data.read_long
              end
              #chan.on_request("exit-signal") do |ch, data|
              #  # TODO: This gets called if the program is killed by a signal
              #  # might also be a worthwhile thing to report
              #  exit_signal = data.read_string.to_i
              #  warn ">>> " + exit_signal.inspect
              #  output.log_command_killed(cmd, exit_signal)
              #end
              chan.on_open_failed do |_ch|
                # TODO: What do do here?
                # I think we should raise something
              end
              chan.on_process do |_ch|
                # TODO: I don't know if this is useful
              end
              chan.on_eof do |_ch|
                # TODO: chan sends EOF before the exit status has been
                # writtend
              end
            end
            chan.wait
          end
          ssh.loop
        end
        # Set exit_status and log the result upon completion
        if exit_status
          cmd.exit_status = exit_status
          output.log_command_exit(cmd)
        end
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

      def with_transfer(summarizer)
        transfer_method = host.transfer_method || self.class.config.transfer_method
        transfer_class = if transfer_method == :sftp
                           require_relative "netssh/sftp_transfer"
                           SftpTransfer
                         else
                           require_relative "netssh/scp_transfer"
                           ScpTransfer
                         end

        with_ssh do |ssh|
          yield(transfer_class.new(ssh, summarizer))
        end
      end
    end
  end

end
