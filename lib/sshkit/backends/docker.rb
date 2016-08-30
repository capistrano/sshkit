require 'open3'
require 'fileutils'
module SSHKit

  module Backend

    class Docker < Abstract
      class Configuration
        attr_accessor :pty, :use_sudo
      end

      IMAGE_CONTAINER_MAP = {}
      CONTAINER_WAIT_IO = {}
      attr_accessor :docker_open_stdin

      def initialize(host, &block)
        super
        @container = nil
      end

      def container
        @container and return @container
        if host.docker_options[:container]
          @container = host.docker_options[:container]
        else
          image = host.docker_options[:image]
          @container = run_image(image)
          host.hostname.chop! << ", container: #{@container})"
        end
        @container
      end

      def upload!(local, remote, _options = {})
        local_io = local
        local_io.is_a?(String) and
          local_io = File.open(local_io, 'rb')
        @docker_open_stdin = true

        with_pty(false) do
          IO.popen(docker_cmd('sh', '-c', "cat > '#{remote}'"), 'wb') do |f|
            IO.copy_stream(local_io, f)
          end
        end

        @docker_open_stdin = false
        local.is_a?(String) and
          local_io.close
      end

      def download!(remote, local=nil, _options = {})
        local_io = local
        local_io.nil? and
          local_io = File.basename(remote)
        local_io.is_a?(String) and
          local_io = File.open(local_io, 'wb')

        with_pty(false) do
          IO.popen(docker_cmd('cat', remote), 'rb') do |f|
            IO.copy_stream(f, local_io)
          end
        end

        local.nil? || local.is_a?(String) and
          local_io.close
      end

      def run_image(image_name)
        IMAGE_CONTAINER_MAP[image_name] and return IMAGE_CONTAINER_MAP[image_name]

        cmd = %w(docker run -i -u 65535:65535)
        %w(volume label label-file link link-local-ip runtime
        cpu-percent cpu-period cpu-quota cpu-shares cpuset-cpus cpuset-mems
        memory memory-reservation security-opt network network-alias
        env env-file dns dns-opt dns-search cap-add cap-drop).each do |opt|
          [*host.docker_options[opt.tr('-', '_').to_sym]].each do |o|
            cmd += ["--#{opt}", o]
          end
        end
        cmd += [image_name, 'sh', '-c', "# SSHkit \n hostname; read _"]
        cmd.unshift('sudo') if Docker.config.use_sudo
        io = IO.popen cmd, 'r+b'
        cid = io.gets
        cid.nil? and raise "Failed to get container ID! (cmd: #{cmd.inspect})"
        at_exit { io.close }
        CONTAINER_WAIT_IO[image_name] = io
        IMAGE_CONTAINER_MAP[image_name] = cid.strip
      end

      def docker_cmd(*args)
        cmd = %w(docker exec)
        cmd << '-it' if Docker.config.pty
        cmd << '-i' if docker_open_stdin
        cmd << '-u' << host.username
        cmd << container
        cmd += args
        cmd.unshift('sudo') if Docker.config.use_sudo
        cmd
      end

      private
      def with_pty(flag)
        orig = Docker.config.pty
        Docker.config.pty = flag
        begin
          yield
        ensure
           Docker.config.pty = orig
        end
      end

      def execute_command(cmd)
        output.log_command_start(cmd)

        cmd.started = Time.now

        Open3.popen3(*docker_cmd('sh', '-c', cmd.to_command)) do |stdin, stdout, stderr, wait_thr|
          stdout_thread = Thread.new do
            while (line = stdout.gets) do
              cmd.on_stdout(stdin, line)
              output.log_command_data(cmd, :stdout, line)
            end
          end

          stderr_thread = Thread.new do
            while (line = stderr.gets) do
              cmd.on_stderr(stdin, line)
              output.log_command_data(cmd, :stderr, line)
            end
          end

          stdout_thread.join
          stderr_thread.join

          cmd.exit_status = wait_thr.value.to_i

          output.log_command_exit(cmd)
        end
      end

    end
  end
end
