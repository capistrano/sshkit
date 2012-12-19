require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'tempfile'
require 'minitest/unit'
require 'mocha'
require 'turn'
require 'debugger'
require 'vagrant'
require 'stringio'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'deploy'


module Vagrant
  module Communication
    class SSH
      def download(from)
        scp_connect do |scp|
          return StringIO.new.tap do |sio|
            scp.download!(from, sio)
          end
        end
      rescue RuntimeError => e
        raise if e.message !~ /Permission denied/
        raise Vagrant::Errors::SCPPermissionDenied, :path => from.to_s
      end
      private
      def scp_connect
        connect do |connection|
          scp = Net::SCP.new(connection)
          return yield scp
        end
      rescue Net::SCP::Error => e
        raise Vagrant::Errors::SCPUnavailable if e.message =~ /\(127\)/
        raise
      end
    end
  end
end

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
    venv.vms.collect do |hostname, vm|

      # Remove the user, make it again, force-generate a key for him
      # short keys save us a few microseconds
      vm.channel.sudo("userdel -rf #{username}; true") # The `rescue nil` of the shell world
      vm.channel.sudo("useradd -m #{username}")
      vm.channel.sudo("echo y | ssh-keygen -b 1024 -f #{username} -N ''")
      vm.channel.sudo("chown vagrant:vagrant #{username}*")
      vm.channel.sudo("echo #{username}:#{password} | chpasswd")

      # Make the .ssh directory, change the ownership and the
      vm.channel.sudo("mkdir -p /home/#{username}/.ssh")
      vm.channel.sudo("chown #{username}:#{username} /home/#{username}/.ssh")
      vm.channel.sudo("chmod 700 /home/#{username}/.ssh")

      # Move the key to authorized keys and chown and chmod it
      vm.channel.sudo("cat #{username}.pub > /home/#{username}/.ssh/authorized_keys")
      vm.channel.sudo("chown #{username}:#{username} /home/#{username}/.ssh/authorized_keys")
      vm.channel.sudo("chmod 600 /home/#{username}/.ssh/authorized_keys")

      sio = vm.channel.download("/home/vagrant/#{username}")

      # Clean Up Files
      vm.channel.sudo("rm #{username} #{username}.pub")

      return sio.tap { |s| s.rewind }.read

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
