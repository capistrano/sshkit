require 'rubygems'
require 'bundler/setup'
require 'tempfile'
require 'minitest/unit'
require 'mocha/setup'
require 'turn'
require 'unindent'
require 'stringio'
require 'json'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'sshkit'

Dir[File.expand_path('test/support/*.rb')].each { |file| require file }

class UnitTest < MiniTest::Unit::TestCase

  def setup
    SSHKit.reset_configuration!
  end

  SSHKit::Backend::ConnectionPool.class_eval do
    def flush_connections
      Thread.current[:sshkit_pool] = {}
    end
  end
end

class FunctionalTest < MiniTest::Unit::TestCase

  def setup
    unless VagrantWrapper.running?
      warn "Vagrant VMs are not running. Please, start it manually with `vagrant up`"
    end
  end

  private

  def create_user_with_key(username, password = :secret)
    username, password = username.to_s, password.to_s

    keys = VagrantWrapper.hosts.collect do |name, host|
      Net::SSH.start(host.hostname, host.user, port: host.port, password: host.password) do |ssh|

        # Remove the user, make it again, force-generate a key for him
        # short keys save us a few microseconds
        ssh.exec!("sudo userdel -rf #{username}; true") # The `rescue nil` of the shell world
        ssh.exec!("sudo useradd -m #{username}")
        ssh.exec!("sudo echo y | ssh-keygen -b 1024 -f #{username} -N ''")
        ssh.exec!("sudo chown vagrant:vagrant #{username}*")
        ssh.exec!("sudo echo #{username}:#{password} | chpasswd")

        # Make the .ssh directory, change the ownership and the
        ssh.exec!("sudo mkdir -p /home/#{username}/.ssh")
        ssh.exec!("sudo chown #{username}:#{username} /home/#{username}/.ssh")
        ssh.exec!("sudo chmod 700 /home/#{username}/.ssh")

        # Move the key to authorized keys and chown and chmod it
        ssh.exec!("sudo cat #{username}.pub > /home/#{username}/.ssh/authorized_keys")
        ssh.exec!("sudo chown #{username}:#{username} /home/#{username}/.ssh/authorized_keys")
        ssh.exec!("sudo chmod 600 /home/#{username}/.ssh/authorized_keys")

        key = ssh.exec!("cat /home/vagrant/#{username}")

        # Clean Up Files
        ssh.exec!("sudo rm #{username} #{username}.pub")

        key
      end
    end

    Hash[VagrantWrapper.hosts.collect { |n, h| n.to_sym }.zip(keys)]
  end

end

#
# Force colours in Autotest
#
Turn.config.ansi = true
Turn.config.format = :pretty

MiniTest::Unit.autorun
