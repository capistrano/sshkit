require 'helper'
require 'sshkit'

module SSHKit
  class TestCommand < UnitTest

    def test_maps_a_command
      c = Command.new('example')
      assert_equal '/usr/bin/env example', c.to_command
    end

    def test_not_mapping_a_builtin
      %w{if test time}.each do |builtin|
        c = Command.new(builtin)
        assert_equal builtin, c.to_command
      end
    end

    def test_multiple_lines_are_stripped_of_extra_space_and_joined_by_semicolons
      c = Command.new <<-EOHEREDOC
        if test ! -d /var/log; then
          echo "Example"
        fi
      EOHEREDOC
      assert_equal "if test ! -d /var/log; then; echo \"Example\"; fi", c.to_command
    end

    def test_leading_and_trailing_space_is_stripped
      c = Command.new(" echo hi ")
      assert_equal "echo hi", c.to_command
    end

    def test_including_the_env
      SSHKit.config = nil
      c = Command.new(:rails, 'server', env: {rails_env: :production})
      assert_equal %{( export RAILS_ENV="production" ; /usr/bin/env rails server )}, c.to_command
    end

    def test_including_the_env_with_multiple_keys
      SSHKit.config = nil
      c = Command.new(:rails, 'server', env: {rails_env: :production, foo: 'bar'})
      assert_equal %{( export RAILS_ENV="production" FOO="bar" ; /usr/bin/env rails server )}, c.to_command
    end

    def test_including_the_env_with_string_keys
      SSHKit.config = nil
      c = Command.new(:rails, 'server', env: {'FACTER_env' => :production, foo: 'bar'})
      assert_equal %{( export FACTER_env="production" FOO="bar" ; /usr/bin/env rails server )}, c.to_command
    end

    def test_double_quotes_are_escaped_in_env
      SSHKit.config = nil
      c = Command.new(:rails, 'server', env: {foo: 'asdf"hjkl'})
      assert_equal %{( export FOO="asdf\\\"hjkl" ; /usr/bin/env rails server )}, c.to_command
    end

    def test_percentage_symbol_handled_in_env
      SSHKit.config = nil
      c = Command.new(:rails, 'server', env: {foo: 'asdf%hjkl'}, user: "anotheruser")
      assert_equal %{( export FOO="asdf%hjkl" ; sudo -u anotheruser FOO=\"asdf%hjkl\" -- sh -c '/usr/bin/env rails server' )}, c.to_command
    end

    def test_including_the_env_doesnt_addressively_escape
      SSHKit.config = nil
      c = Command.new(:rails, 'server', env: {path: '/example:$PATH'})
      assert_equal %{( export PATH="/example:$PATH" ; /usr/bin/env rails server )}, c.to_command
    end

    def test_global_env
      SSHKit.config = nil
      SSHKit.config.default_env = { default: 'env' }
      c = Command.new(:rails, 'server', env: {})
      assert_equal %{( export DEFAULT="env" ; /usr/bin/env rails server )}, c.to_command
    end

    def test_default_env_is_overwritten_with_locally_defined
      SSHKit.config.default_env = { foo: 'bar', over: 'under' }
      c = Command.new(:rails, 'server', env: { over: 'write'})
      assert_equal %{( export FOO="bar" OVER="write" ; /usr/bin/env rails server )}, c.to_command
    end

    def test_working_in_a_given_directory
      c = Command.new(:ls, '-l', in: "/opt/sites")
      assert_equal "cd /opt/sites && /usr/bin/env ls -l", c.to_command
    end

    def test_working_in_a_given_directory_with_env
      c = Command.new(:ls, '-l', in: "/opt/sites", env: {a: :b})
      assert_equal %{cd /opt/sites && ( export A="b" ; /usr/bin/env ls -l )}, c.to_command
    end

    def test_having_a_host_passed
      refute Command.new(:date).host
      assert Command.new(:date, host: :foo)
      assert_equal :foo, Command.new(host: :foo).host
    end

    def test_working_as_a_given_user
      c = Command.new(:whoami, user: :anotheruser)
      assert_equal "sudo -u anotheruser -- sh -c '/usr/bin/env whoami'", c.to_command
    end

    def test_working_as_a_given_group
      c = Command.new(:whoami, group: :devvers)
      assert_equal "sg devvers -c \\\"/usr/bin/env whoami\\\"", c.to_command
    end

    def test_working_as_a_given_user_and_group
      c = Command.new(:whoami, user: :anotheruser, group: :devvers)
      assert_equal "sudo -u anotheruser -- sh -c 'sg devvers -c \\\"/usr/bin/env whoami\\\"'", c.to_command
    end

    def test_umask
      SSHKit.config.umask = '007'
      c = Command.new(:touch, 'somefile')
      assert_equal "umask 007 && /usr/bin/env touch somefile", c.to_command
    end

    def test_umask_with_working_directory
      SSHKit.config.umask = '007'
      c = Command.new(:touch, 'somefile', in: '/opt')
      assert_equal "cd /opt && umask 007 && /usr/bin/env touch somefile", c.to_command
    end

    def test_umask_with_working_directory_and_user
      SSHKit.config.umask = '007'
      c = Command.new(:touch, 'somefile', in: '/var', user: 'alice')
      assert_equal "cd /var && umask 007 && sudo -u alice -- sh -c '/usr/bin/env touch somefile'", c.to_command
    end

    def test_umask_with_env_and_working_directory_and_user
      SSHKit.config.umask = '007'
      c = Command.new(:touch, 'somefile', user: 'bob', env: {a: 'b'}, in: '/var')
      assert_equal %{cd /var && umask 007 && ( export A="b" ; sudo -u bob A="b" -- sh -c '/usr/bin/env touch somefile' )}, c.to_command
    end

    def test_verbosity_defaults_to_logger_info
      assert_equal Logger::INFO, Command.new(:ls).verbosity
    end

    def test_overriding_verbosity_level_with_a_constant
      assert_equal Logger::DEBUG, Command.new(:ls, verbosity: Logger::DEBUG).verbosity
    end

    def test_overriding_verbosity_level_with_a_symbol
      assert_equal Logger::DEBUG, Command.new(:ls, verbosity: :debug).verbosity
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

    def test_on_stdout
      c = Command.new(:whoami)
      c.on_stdout(nil, "test\n")
      c.on_stdout(nil, 'test2')
      c.on_stdout(nil, 'test3')
      assert_equal "test\ntest2test3", c.full_stdout
    end

    def test_on_stderr
      c = Command.new(:whoami)
      c.on_stderr(nil, 'test')
      assert_equal 'test', c.full_stderr
    end

    def test_deprecated_stdtream_accessors
      deprecation_out = ''
      SSHKit.config.deprecation_output = deprecation_out

      c = Command.new(:whoami)
      c.stdout='a test'
      assert_equal('a test', c.stdout)
      c.stderr='another test'
      assert_equal('another test', c.stderr)
      deprecation_lines = deprecation_out.lines.to_a

      assert_equal 8, deprecation_lines.size
      assert_equal(
        '[Deprecated] The stdout= method on Command is deprecated. ' +
        "The @stdout attribute will be removed in a future release.\n",
        deprecation_lines[0])
      assert_equal(
        '[Deprecated] The stdout method on Command is deprecated. ' +
        "The @stdout attribute will be removed in a future release. Use full_stdout() instead.\n",
        deprecation_lines[2])

      assert_equal(
        '[Deprecated] The stderr= method on Command is deprecated. ' +
        "The @stderr attribute will be removed in a future release.\n",
        deprecation_lines[4])
      assert_equal(
        '[Deprecated] The stderr method on Command is deprecated. ' +
        "The @stderr attribute will be removed in a future release. Use full_stderr() instead.\n",
        deprecation_lines[6])
    end

    def test_setting_exit_status
      c = Command.new(:whoami, raise_on_non_zero_exit: false)
      assert_nil c.exit_status
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
      assert_equal "whoami exit status: 1\nwhoami stdout: Nothing written\nwhoami stderr: Nothing written\n", error.message
    end

  end
end
