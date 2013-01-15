require 'helper'

module Deploy
  class TestCommand < UnitTest

    def test_execute_returns_command
      c = Command.new('test')
      assert_equal '/usr/bin/env test', String(c)
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
      assert_equal "cd /opt/sites && /usr/bin/env ls -l; cd -", String(c)
    end

    def test_working_in_a_given_directory_with_env
      c = Command.new(:ls, '-l', in: "/opt/sites", env: {a: :b})
      assert_equal "cd /opt/sites && ( A=b /usr/bin/env ls -l ); cd -", String(c)
    end

  end
end
