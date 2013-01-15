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
        _execute(*args).stdout.strip
      end

      private

      def _execute(*args)
        command(*args).tap do |cmd|
          output << cmd
          ssh.open_channel do |chan|
            chan.exec cmd.to_s do |ch, success|
              # TODO: Something about checking success
              chan.on_data do |ch, data|
                cmd.stdout += data
                output << cmd
              end
              chan.on_extended_data do |ch, type, data|
                cmd.stderr += data
                output << cmd
              end
              chan.on_request("exit-status") do |ch, data|
                exit_status = data.read_string.to_i
                cmd.exit_status = exit_status
                output << cmd
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
