require 'open3'
require 'fileutils'
module SSHKit

  module Backend

    class Docker < Abstract
      class Configuration
        attr_accessor :pty, :use_sudo
      end

      CONTAINER_MAP = {}
      CONTAINER_WAIT_IO = {}
      attr_accessor :docker_open_stdin

      def self.find_cntainer_by_host(host)
        host.docker_options[:container] || CONTAINER_MAP[host.docker_options]
      end

      def initialize(host, &block)
        super
        @container = nil
      end

      def container
        @container and return @container
        if host.docker_options[:container]
          @container = host.docker_options[:container]
        else
          @container = run_image
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

      def merged_env
        menv = (SSHKit.config.default_env || {}).dup.symbolize_keys
        [*host.docker_options[:env_file]].each do |ef|
          File.foreach(ef) do |line|
            line.include? "=" or next
            key, val = line.chomp.split('=', 2)
            menv[key.strip.to_sym] = val.strip
          end
        end
        if host.docker_options[:env].is_a?(Hash)
          host.docker_options[:env].each do |key, val|
            menv[key.to_sym] = val
          end
        else
          [*host.docker_options[:env]].each do |e|
            key, val = e.split('=', 2)
            menv[key.strip.to_sym] = val.strip
          end
        end
        if menv[:rails_env]
          menv[:RAILS_ENV] = menv.delete(:rails_env)
        end
        menv
      end

      def run_image(host = nil)
        host ||= self.host
        CONTAINER_MAP[host.docker_options] and
          return CONTAINER_MAP[host.docker_options]

        image_name = host.docker_options[:image]
        cmd = %w(docker run -i)
        host.docker_options.each do |key, val|
          %w(container image env env_file commit).member?(key.to_s) and next
          [*val].each do |v|
            cmd << "--#{key.to_s.tr('_', '-')}" << v
          end
        end
        merged_env.each do |key, val|
          cmd << "-e" << "#{key}=#{val}"
        end
        cmd += [image_name, 'sh', '-c', "# SSHkit \n hostname; read _"]
        cmd.unshift('sudo') if Docker.config.use_sudo
        io = IO.popen cmd, 'r+b'
        cid = io.gets
        cid.nil? and raise "Failed to get container ID! (cmd: #{cmd.inspect})"
        at_exit { io.close }
        CONTAINER_WAIT_IO[host.docker_options] = io
        CONTAINER_MAP[host.docker_options] = cid.strip
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
