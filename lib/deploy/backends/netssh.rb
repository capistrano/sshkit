module Deploy
  module Backend

    class Netssh < Printer

      include Deploy::CommandHelper

      def run
        instance_exec(host, &@block)
      end

      def execute(*args)
        _execute(*args).success?
      end

      def capture(*args)
        _execute(*args).stdout
      end

      private

      def _execute(*args)
        command(*args).tap do |cmd|
          output << cmd
          ssh.open_channel do |chan|
            chan.request_pty do |_, success|
              if success
                warn 'pty request successful'
              else
                warn 'pty request failed'
              end
            end
            chan.exec String(command) do |ch, success|
              # TODO: Something about checking success
              chan.on_data do |ch, data|
                warn "STDOUT: #{data}"
                cmd.stdout += data
                output << cmd
              end
              chan.on_extended_data do |ch, type, data|
                warn "STDERR: ##{type} #{data}"
                cmd.stderr += data
                output << cmd
              end
              chan.on_request("exit-status") do |ch, data|
                exit_status = data.read_string.to_i
                warn "EXIT_STATUS: #{exit_status}"
                cmd.exit_status = exit_status
                output << cmd
              end
            end
            chan.wait
          end
          warn "jumping ssh loop"
          ssh.loop
          warn "Abandoning SSH loop"
        end
      end

      def ssh
        @ssh ||= begin
          Net::SSH.start(
            host.hostname,
            host.username,
            port: host.port,
            password: host.password
          )
        end
      end

    end
  end

end
