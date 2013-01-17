require 'helper'
require 'sshkit'

module SSHKit
  class TestCommand < UnitTest

    def test_maps_a_command
      c = Command.new('example')
      assert_equal '/usr/bin/env example', String(c)
    end

    def test_not_mapping_a_builtin
      %w{if test time}.each do |builtin|
        c = Command.new(builtin)
        assert_equal builtin, String(c)
      end
    end

    def test_using_a_heredoc
      c = Command.new <<-EOHEREDOC
        if test ! -d /var/log; then
          echo "Example"
        fi
      EOHEREDOC
      assert_equal "if test ! -d /var/log; then; echo \"Example\"; fi", String(c)
    end

    def test_including_the_env
      c = Command.new(:rails, 'server', env: {rails_env: :production})
      assert_equal "( RAILS_ENV=production /usr/bin/env rails server )", String(c)
    end

    def test_working_in_a_given_directory
      c = Command.new(:ls, '-l', in: "/opt/sites")
      assert_equal "cd /opt/sites && /usr/bin/env ls -l", String(c)
    end

    def test_working_in_a_given_directory_with_env
      c = Command.new(:ls, '-l', in: "/opt/sites", env: {a: :b})
      assert_equal "cd /opt/sites && ( A=b /usr/bin/env ls -l )", String(c)
    end

    def test_having_a_host_passed
      refute Command.new(:date).host
      assert Command.new(:date, host: :foo)
      assert_equal :foo, Command.new(host: :foo).host
    end

    def test_working_as_a_given_user
      c = Command.new(:whoami, user: :anotheruser)
      assert_equal "sudo su anotheruser -c /usr/bin/env whoami", String(c)
    end

    def test_backgrounding_a_task
      c = Command.new(:sleep, 15, run_in_background: true)
      assert_equal "nohup /usr/bin/env sleep 15 > /dev/null &", String(c)
    end

    def test_backgrounding_a_task_as_a_given_user
      c = Command.new(:sleep, 15, run_in_background: true, user: :anotheruser)
      assert_equal "sudo su anotheruser -c nohup /usr/bin/env sleep 15 > /dev/null &", String(c)
    end

    def test_backgrounding_a_task_as_a_given_user_with_env
      c = Command.new(:sleep, 15, run_in_background: true, user: :anotheruser, env: {a: :b})
      assert_equal "( A=b sudo su anotheruser -c nohup /usr/bin/env sleep 15 > /dev/null & )", String(c)
    end

    def test_complete?
      c = Command.new(:whoami, raise_on_non_zero_exit: false)
      refute c.complete?
      c.exit_status = 1
      assert c.complete?
      c.exit_status = 0
      assert c.complete?
    end

    def test_successful?
      c = Command.new(:whoami)
      refute c.successful?
      refute c.success?
      c.exit_status = 0
      assert c.successful?
      assert c.success?
    end

    def test_failure?
      c = Command.new(:whoami, raise_on_non_zero_exit: false)
      refute c.failure?
      refute c.failed?
      c.exit_status = 1
      assert c.failure?
      assert c.failed?
      c.exit_status = 127
      assert c.failure?
      assert c.failed?
    end

    def test_appending_stdout
      c = Command.new(:whoami)
      assert c.stdout += "test\n"
      assert_equal "test\n", c.stdout
    end

    def test_appending_stderr
      c = Command.new(:whoami)
      assert c.stderr += "test\n"
      assert_equal "test\n", c.stderr
    end

    def test_setting_exit_status
      c = Command.new(:whoami, raise_on_non_zero_exit: false)
      assert_equal nil, c.exit_status
      assert c.exit_status = 1
      assert_equal 1, c.exit_status
    end

    def test_command_has_a_guid
      assert Command.new(:whosmi).uuid
    end

    def test_wont_take_no_args
      assert_raises ArgumentError do
        Command.new
      end
    end

    def test_command_raises_command_failed_error_when_non_zero_exit
      error = assert_raises SSHKit::Command::Failed do
        Command.new(:whoami).exit_status = 1
      end
      assert_equal "No messages written to stderr", error.message
    end

  end
end
