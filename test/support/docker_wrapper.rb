Minitest.after_run do
  DockerWrapper.stop if DockerWrapper.running?
end

module DockerWrapper
  class << self
    def host
      SSHKit::Host.new(
        user: "deployer",
        hostname: "localhost",
        port: "2122",
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

    private

    def run_compose_command(command, echo=true)
      $stderr.puts "[docker compose] #{command}" if echo
      stdout, stderr, status = Open3.capture3("docker compose #{command}")

      output = stdout + stderr
      output.each_line { |line| $stderr.puts "[docker compose] #{line}" } if echo

      [output, status]
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