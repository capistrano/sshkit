require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/unit'
require 'mocha'
require 'turn'
require 'debugger'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'deploy'
require 'support/sshd'
require 'support/sshd_user_with_key'

class UnitTest < MiniTest::Unit::TestCase

end

class FunctionalTest < MiniTest::Unit::TestCase

  def setup
    SSH.daemon.stop if SSH.daemon.running?
    SSH.write_configurations!
    SSH.daemon.start
    assert SSH.daemon.running?
  end

  def teardown
    SSH.daemon.stop
    refute SSH.daemon.running?
  end

end

class IntegrationTest < MiniTest::Unit::TestCase

end

#
# Force colours in Autotest
#
Turn.config.ansi = true

MiniTest::Unit.autorun
