VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'bento/ubuntu-22.10'
  config.vm.boot_timeout = 600 # seconds
  config.vm.provider 'virtualbox' do |vb|
    vb.memory = 1024
    vb.cpus = 1

    # https://github.com/hashicorp/vagrant/issues/11777#issuecomment-661076612
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
  end
  config.ssh.insert_key = false
  config.vm.provision "shell", inline: <<-SHELL
  echo 'ClientAliveInterval 3' >> /etc/ssh/sshd_config
  echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config
  echo 'MaxAuthTries 6' >> /etc/ssh/sshd_config
  service ssh restart
  SHELL

  json_config_path = File.join("test", "boxes.json")
  list = File.open(json_config_path).read
  list = JSON.parse(list)

  list.each do |vm|
    config.vm.define vm["name"] do |web|
      web.vm.network "forwarded_port", guest: 22, host: vm["port"]
    end
  end
end
