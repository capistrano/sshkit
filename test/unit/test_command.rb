require 'helper'

module Deploy
  class TestCommand < UnitTest

    def test_execute_returns_command
      c = Command.new('test')
      assert_equal 'test', String(c)
      assert_equal 'test', c.to_s
    end
    
    def test_shell_escaping
      c = Command.new('rm', '-rf', 'hello world')
      assert_equal 'rm -rf hello\ world', String(c)
      assert_equal 'rm -rf hello\ world', c.to_s
    end

  end
end
