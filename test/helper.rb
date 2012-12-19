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
require 'vagrant'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'deploy'
require 'support/sshd'
require 'support/sshd_user_with_key'

class UnitTest < MiniTest::Unit::TestCase

end

class FunctionalTest < MiniTest::Unit::TestCase

  attr_accessor :venv

  def setup
    @venv = Vagrant::Environment.new
    venv.vms.each do |name, vm|
      warn "#{name} (of #{venv.vms.size}) needs to be booted, please wait" unless vm.state == :running
    end
    venv.cli "up"
  end

  private

  def create_user_with_key(username, password = :secret)
    username, password = username.to_s, password.to_s
    venv.vms.each do |name, vm|
      # Remove the user, make it again, force-generate a key for him
      # short keys save us a few microseconds
      vm.channel.sudo("userdel -rf #{username}; true") # The `rescue nil` of the shell world
      vm.channel.sudo("useradd -m #{username}")
      vm.channel.sudo("echo y | ssh-keygen -b 1024 -f #{username} -N ''")
      vm.channel.sudo("echo #{username}:#{password} | chpasswd")

      # Make the .ssh directory, change the ownership and the
      vm.channel.sudo("mkdir -p /home/#{username}/.ssh")
      vm.channel.sudo("chown #{username}:#{username} /home/#{username}/.ssh")
      vm.channel.sudo("chmod 700 /home/#{username}/.ssh")

      # Move the key to authorized keys and chown and chmod it
      vm.channel.sudo("cat #{username}.pub > /home/#{username}/.ssh/authorized_keys")
      vm.channel.sudo("chown #{username}:#{username} /home/#{username}/.ssh/authorized_keys")
      vm.channel.sudo("chmod 600 /home/#{username}/.ssh/authorized_keys")
    end
  end

end

class IntegrationTest < MiniTest::Unit::TestCase

end

#
# Force colours in Autotest
#
Turn.config.ansi = true

MiniTest::Unit.autorun
