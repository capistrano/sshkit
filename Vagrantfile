VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'hashicorp/precise64'
  config.vm.provision "shell", inline: <<-SHELL
  echo 'ClientAliveInterval 1' >> /etc/ssh/sshd_config
  echo 'ClientAliveCountMax 1' >> /etc/ssh/sshd_config
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
