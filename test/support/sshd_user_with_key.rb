require 'pathname'

class SSHUser

  def self.create(username)
    self.new(username).setup
  end

  def self.teardown(username)
    self.new(username).teardown
  end

  attr_accessor :username

  def initialize(username)
    @username = username.to_s
  end

  def setup
    FileUtils.mkdir_p ssh_key_dir
    `echo 'Y' | ssh-keygen -b 1024 -f #{ssh_key_dir + 'id_rsa'} -N ''`
    `cat #{ssh_key_dir + 'id_rsa.pub'} > #{authorized_keys_file}`
    `chmod 600 #{authorized_keys_file}`
    ssh_key_dir + 'id_rsa'
  end

  def teardown
    FileUtils.rm_rf(working_root + username)
  end

  private

  def authorized_keys_file
    ssh_key_dir + 'authorized_keys'
  end

  def working_root
    Pathname.new File.join(Dir.pwd, %w{test tmp sshd sandbox})
  end

  def ssh_key_dir
    working_root + username + '.ssh'
  end

end
