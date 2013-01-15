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
              chan.on_request("exit-signal") do |ch, data|
                # TODO: This gets called if the program is killed by a signal
                # might also be a worthwhile thing to report
                exit_status = data.read_string.to_i
                cmd.exit_status = exit_status
                output << cmd
              end
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
