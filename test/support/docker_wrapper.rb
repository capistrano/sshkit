require "socket"

Minitest.after_run do
  DockerWrapper.stop if DockerWrapper.running?
end

module DockerWrapper
  SSH_SERVER_PORT = 2122

  class << self
    def host
      SSHKit::Host.new(
        user: "deployer",
        hostname: "localhost",
        port: SSH_SERVER_PORT,
        password: "topsecret",
        ssh_options: host_verify_options
      )
    end

    def running?
      out, status = run_compose_command("ps --status running", false)
      status.success? && out.include?("ssh_server")
    end

    def start
      run_compose_command("up -d")
    end

    def stop
      run_compose_command("down")
    end

    def wait_for_ssh_server(retries=3)
      Socket.tcp("localhost", SSH_SERVER_PORT, connect_timeout: 1).close
      sleep(1)
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
      retries -= 1
      sleep(2) && retry if retries.positive?
      raise
    end

    private

    def run_compose_command(command, echo=true)
      $stderr.puts "[docker compose] #{command}" if echo
      Open3.popen2e("docker compose #{command}") do |stdin, outerr, wait_thread|
        stdin.close
        output = Thread.new { capture_stream(outerr, echo) }
        [output.value, wait_thread.value]
      end
    end

    def capture_stream(stream, echo=true)
      buffer = String.new
      while (line = stream.gets)
        buffer << line
        $stderr.puts("[docker compose] #{line}") if echo
      end
      buffer
    end

    def host_verify_options
      if Net::SSH::Version::MAJOR >= 5
        { verify_host_key: :never }
      else
        { paranoid: false }
      end
    end
  end
end
