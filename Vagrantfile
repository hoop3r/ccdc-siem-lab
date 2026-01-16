Vagrant.configure("2") do |config|

  UBUNTU_BOX = "generic/ubuntu2204"
  KALI_BOX   = "kalilinux/rolling"
  PRIVATE_NET = "192.168.56"

  config.vm.provider :libvirt do |lv|
    lv.driver = "kvm"
  end

  # WAZUH

  config.vm.define "wazuh-manager" do |mgr|
    mgr.vm.box = UBUNTU_BOX
    mgr.vm.hostname = "wazuh-manager"
    mgr.vm.network "private_network", ip: "#{PRIVATE_NET}.10"

    mgr.vm.provider :libvirt do |lv|
      lv.memory = 4096
      lv.cpus = 2
    end

    mgr.vm.provision "shell", path: "scripts/provision-wazuh-manager.sh"
  end

  # VULNERABLE WEB SERVER

  config.vm.define "vuln-web" do |web|
    web.vm.box = UBUNTU_BOX
    web.vm.hostname = "vuln-web"
    web.vm.network "private_network", ip: "#{PRIVATE_NET}.20"

    web.vm.provider :libvirt do |lv|
      lv.memory = 2048
      lv.cpus = 1
    end

    web.vm.provision "shell", path: "scripts/provision-vuln-web.sh"
  end

  # KALI WORKSTATION

  config.vm.define "kali" do |kali|
    kali.vm.box = KALI_BOX
    kali.vm.hostname = "kali"
    kali.vm.network "private_network", ip: "#{PRIVATE_NET}.30"

    kali.vm.provider :libvirt do |lv|
      lv.memory = 4096
      lv.cpus = 2
    end

    kali.vm.provision "shell", path: "scripts/provision-kali.sh"
  end
end
