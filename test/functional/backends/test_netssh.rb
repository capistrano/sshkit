require 'helper'
require 'benchmark'

module SSHKit

  module Backend

    class TestNetssh < FunctionalTest

      def setup
        super
        @output = String.new
        SSHKit.config.output_verbosity = :debug
        SSHKit.config.output = SSHKit::Formatter::SimpleText.new(@output)
      end

      def a_host
        DockerWrapper.host
      end

      def test_simple_netssh
        Netssh.new(a_host) do
          execute 'date'
          execute :ls, '-l'
          with rails_env: :production do
           within '/tmp' do
             as :root do
               execute :touch, 'restart.txt'
             end
           end
          end
        end.run

        command_lines = @output.lines.select { |line| line.start_with?('Command:') }
        assert_equal [
          "Command: /usr/bin/env date\n",
          "Command: /usr/bin/env ls -l\n",
          "Command: if test ! -d /tmp; then echo \"Directory does not exist '/tmp'\" 1>&2; false; fi\n",
          "Command: if ! sudo -u root whoami > /dev/null; then echo \"You cannot switch to user 'root' using sudo, please check the sudoers file\" 1>&2; false; fi\n",
          "Command: cd /tmp && ( export RAILS_ENV=\"production\" ; sudo -u root RAILS_ENV=\"production\" -- sh -c /usr/bin/env\\ touch\\ restart.txt )\n"
        ], command_lines
      end

      def test_redaction
        # Be sure redaction in the logs is showing [REDACTED]
        Netssh.new(a_host) do
          execute :echo, 'password:', redact('PASSWORD')
          execute :echo, 'password:', redact(10000)
          execute :echo, 'password:', redact(['test1','test2'])
          execute :echo, 'password:', redact({:test => 'test_value'})
        end.run
        command_lines = @output.lines.select { |line| line.start_with?('Command:') }
        assert_equal [
                         "Command: /usr/bin/env echo password: [REDACTED]\n",
                         "Command: /usr/bin/env echo password: [REDACTED]\n",
                         "Command: /usr/bin/env echo password: [REDACTED]\n",
                         "Command: /usr/bin/env echo password: [REDACTED]\n"
                     ], command_lines
        # Be sure the actual command executed without *REDACTED*
        Netssh.new(a_host) do
          file_name = 'test.file'
          execute :touch, redact("'#{file_name}'") # Test and be sure single quotes are included in actual command; expected /usr/bin/env touch 'test.file'
          execute :ls, 'test.file'
        end.run
        ls_lines = @output.lines.select { |line| line.start_with?("\ttest.file") }
        assert_equal [
                         "\ttest.file\n"
                     ], ls_lines
        # Cleanup
        Netssh.new(a_host) do
          execute :rm, ' -f test.file'
        end.run
      end

      def test_group_netssh
        Netssh.new(a_host) do
          as user: :root, group: :root do
           execute :touch, 'restart.txt'
          end
        end.run
        command_lines = @output.lines.select { |line| line.start_with?('Command:') }
        assert_equal [
          "Command: if ! sudo -u root whoami > /dev/null; then echo \"You cannot switch to user 'root' using sudo, please check the sudoers file\" 1>&2; false; fi\n",
          "Command: sudo -u root -- sh -c sg\\ root\\ -c\\ /usr/bin/env\\\\\\ touch\\\\\\ restart.txt\n"
        ], command_lines
      end

      def test_capture
        captured_command_result = nil
        Netssh.new(a_host) do |_host|
          captured_command_result = capture(:uname)
        end.run

        assert_includes %W(Linux Darwin), captured_command_result
      end

      def test_ssh_option_merge
        keepalive_opt = { keepalive: true }
        test_host = a_host.dup
        test_host.ssh_options = keepalive_opt
        host_ssh_options = {}
        SSHKit::Backend::Netssh.config.ssh_options = { forward_agent: false }
        Netssh.new(test_host) do |host|
          capture(:uname)
          host_ssh_options = host.ssh_options
        end.run
        assert_equal [:forward_agent, *keepalive_opt.keys, :known_hosts, :logger, :password_prompt].sort, host_ssh_options.keys.sort
        assert_equal false, host_ssh_options[:forward_agent]
        assert_equal keepalive_opt.values.first, host_ssh_options[keepalive_opt.keys.first]
        assert_instance_of SSHKit::Backend::Netssh::KnownHosts, host_ssh_options[:known_hosts]
      end

      def test_env_vars_substituion_in_subshell
        captured_command_result = nil
        Netssh.new(a_host) do |_host|
          with some_env_var: :some_value do
           captured_command_result = capture(:echo, '$SOME_ENV_VAR')
          end
        end.run
        assert_equal "some_value", captured_command_result
      end

      def test_execute_raises_on_non_zero_exit_status_and_captures_stdout_and_stderr
        err = assert_raises SSHKit::Command::Failed do
          Netssh.new(a_host) do |_host|
            execute :echo, "'Test capturing stderr' 1>&2; false"
          end.run
        end
        assert_equal "echo exit status: 1\necho stdout: Nothing written\necho stderr: Test capturing stderr\n", err.message
      end

      def test_test_does_not_raise_on_non_zero_exit_status
        Netssh.new(a_host) do |_host|
          test :false
        end.run
      end

      def test_interaction_handler
        captured_command_result = nil
        Netssh.new(a_host) do
          command = 'echo Enter Data; read the_data; echo Captured $the_data;'
          captured_command_result = capture(command, interaction_handler: {
            "Enter Data\n" => "SOME DATA\n",
            "Captured SOME DATA\n" => nil
          })
        end.run
        assert_equal("Enter Data\nCaptured SOME DATA", captured_command_result)
      end

      def test_connection_pool_keepalive
        # ensure we enable connection pool
        SSHKit::Backend::Netssh.pool.idle_timeout = 10
        Netssh.new(a_host) do |_host|
          test :false
        end.run
        sleep 2.5
        captured_command_result = nil
        Netssh.new(a_host) do |_host|
          captured_command_result = capture(:echo, 'some_value')
        end.run
        assert_equal "some_value", captured_command_result
      end
    end

  end

end
