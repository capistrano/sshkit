require 'net/ssh'

module SSHKit
  module Backend

    class Netssh < Printer

      class Configuration
        attr_accessor :connection_timeout, :pty
      end

      include SSHKit::CommandHelper

      def run
        instance_exec(host, &@block)
      end

      def test(*args)
        options = args.extract_options!.merge(
          raise_on_non_zero_exit: false,
          verbosity: Logger::DEBUG
        )
        _execute(*[*args, options]).success?
      end

      def execute(*args)
        _execute(*args).success?
      end

      def background(*args)
        options = args.extract_options!.merge(run_in_background: true)
        _execute(*[*args, options]).success?
      end

      def capture(*args)
        options = args.extract_options!.merge(verbosity: Logger::DEBUG)
        _execute(*[*args, options]).success?
      end

      def configure
        yield config
      end

      def config
        @config ||= Configuration.new
      end

      private

      def _execute(*args)
        command(*args).tap do |cmd|
          output << cmd
          cmd.started = true
          ssh.open_channel do |chan|
            chan.request_pty if config.pty
            chan.exec cmd.to_s do |ch, success|
              chan.on_data do |ch, data|
                cmd.stdout += data
                output << cmd
              end
              chan.on_extended_data do |ch, type, data|
                cmd.stderr += data
                output << cmd
              end
              chan.on_request("exit-status") do |ch, data|
                exit_status = data.read_long
                cmd.exit_status = exit_status
                output << cmd
              end
              #chan.on_request("exit-signal") do |ch, data|
              #  # TODO: This gets called if the program is killed by a signal
              #  # might also be a worthwhile thing to report
              #  exit_signal = data.read_string.to_i
              #  warn ">>> " + exit_signal.inspect
              #  output << cmd
              #end
              chan.on_open_failed do |ch|
                # TODO: What do do here?
                # I think we should raise something
              end
              chan.on_process do |ch|
                # TODO: I don't know if this is useful
              end
              chan.on_eof do |ch|
                # TODO: chan sends EOF before the exit status has been
                # writtend
              end
            end
            chan.wait
          end
          ssh.loop
        end
      end

      def ssh
        @ssh ||= begin
          Net::SSH.start(
            host.hostname,
            host.username,
            port: host.port,
            password: host.password,
          )
        end
      end

    end
  end

end
