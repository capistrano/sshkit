require 'net/ssh'
require 'net/scp'

module Net
  module SSH
    class Config
      class << self
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
          @ssh_options || {}
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

      @pool = SSHKit::Backend::ConnectionPool.new

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

    end
  end

end
