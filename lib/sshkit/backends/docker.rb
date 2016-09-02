require 'open3'
require 'fileutils'
require 'json'
module SSHKit

  module Backend

    class Docker < Abstract
      class Configuration
        attr_accessor :pty, :use_sudo
      end

      CONTAINER_MAP = {}
      CONTAINER_WAIT_IO = {}
      attr_accessor :docker_open_stdin

      def self.host_container_map_key(host)
        key = host.docker_options.dup || {}
        key.delete :container
        key.delete :commit
        key
      end

      def self.find_cntainer_by_host(host)
        host.docker_options[:container] ||
          CONTAINER_MAP[host_container_map_key(host)]
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
          @container = docker_run_image
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
          IO.popen(to_docker_cmd('sh', '-c', "cat > '#{remote}'"), 'wb') do |f|
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
          IO.popen(to_docker_cmd('cat', remote), 'rb') do |f|
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

      def docker_run_image(host = nil)
        host ||= self.host

        if host.is_a?(String)
          image_name = host
          host = _deep_dup(self.host)
          host.docker_options[:image] = image_name
        elsif host.is_a?(Hash)
          d_opts = host
          host = _deep_dup(self.host)
          host.docker_options = d_opts.symbolize_keys
        end

        map_key = self.class.host_container_map_key(host)
        CONTAINER_MAP[map_key] and
          return CONTAINER_MAP[map_key]

        image_name = host.docker_options[:image]
        cmd = %w(docker run -i)
        host.docker_options.each do |key, val|
          %w(container image env env_file commit).member?(key.to_s) and next
          if %w(t tty h hostname attach d detach entrypoint rm).member?(key.to_s)
            output.warn "Docker: run option '#{key}' is filtered."
            next
          end
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
        if cid.nil?
          output.fatal "Docker: Failed to run image #{image_name}"
          raise "Failed to get container ID! (cmd: #{cmd.inspect})"
        end
        at_exit { io.close }
        CONTAINER_WAIT_IO[map_key] = io
        CONTAINER_MAP[map_key] = cid.strip
        output.info "Docker: run new container #{CONTAINER_MAP[map_key]} from image #{image_name}"
        CONTAINER_MAP[map_key]
      end

      def docker_commit(host = nil)
        host ||= self.host

        if host.is_a?(String)
          commit_id = host
          host = _deep_dup(self.host)
          host.docker_options[:commit] = commit_id
        elsif host.is_a?(Hash)
          commit_info = host
          host = _deep_dup(self.host)
          host.docker_options[:commit] ||= {}
          host.docker_options[:commit].update commit_info.symbolize_keys
        end

        host.docker_options[:commit] or return

        container = self.class.find_cntainer_by_host(host) or
          raise "Cannot find container for host #{host.inspect}"

        cmd = %w(docker commit)

        if host.docker_options[:image]
          # if container is delivered from image, recover USER and CMD.
          image_config = {}
          IO.popen ['docker', 'inspect', '-f', '{{json .Config}}', host.docker_options[:image]], 'rb' do |f|
            image_config = JSON.parse(f.read.chomp)
          end

          if image_config["User"].to_s.length > 1
            cmd << '-c' << "USER #{image_config["User"]}"
          end

          c = image_config["Cmd"]
          if c[0] == "/bin/sh" && c[1] == "-c"
            c.shift; c.shift;
          end
          unless c.empty?
            cmd << '-c' << "CMD #{c.join(' ')}"
          end
        end

        image_name = host.docker_options[:commit]
        if image_name.is_a?(Hash)
          image_name.symbolize_keys.each do |key, val|
            if key == :name
              image_name = val
            else
              [*val].each do |v|
                cmd << "--#{key.to_s.tr('_', '-')}" << v
              end
            end
          end
        end
        cmd << container
        image_name == true or
          cmd << image_name

        image_hash = nil
        pid = nil
        IO.popen cmd, 'rb' do |f|
          pid = f.pid
          image_hash = f.gets
        end
        image_hash.nil? and
          output.error "Docker: Failed to get image hash. Commit may be failed!"
        image_hash.chomp!
        ret = image_name == true ? image_hash : image_name
        output.info "Docker: commit #{container} as #{ret}"
        ret
      end

      def to_docker_cmd(*args)
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

        Open3.popen3(*to_docker_cmd('sh', '-c', cmd.to_command)) do |stdin, stdout, stderr, wait_thr|
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

      def _deep_dup(obj)
        Marshal.load Marshal.dump(obj)
      end

    end
  end
end
