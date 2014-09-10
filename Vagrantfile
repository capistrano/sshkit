VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'precise64'
  config.vm.provider "vmware_fusion" do |vmf|
    vmf.box_url = "http://files.vagrantup.com/precise64_vmware.box"
  end
  config.vm.provider "virtualbox" do |vb|
    config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/precise/current/precise-server-cloudimg-amd64-vagrant-disk1.box"
  end

  json_config_path = File.join("test", "boxes.json")
  list = File.open(json_config_path).read
  list = JSON.parse(list)

  list.each do |vm|
    config.vm.define vm["name"] do |web|
      web.vm.box = "precise64"
      web.vm.network "forwarded_port", guest: 22, host: vm["port"]
    end
  end
end
