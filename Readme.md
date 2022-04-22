## Prepare for Kubernetes Advance Course

<br> </br>

### 1. Labtop Consideration & Software Pre-Install Prerequiment

- To easier for you to follow this course, I recommend you should have labtop at least `16G` Ram & high model `CPU`.

- We will using Vargant `2.2.28` and VirtualBox `6.1.22` for create VMs to provision our kubernetes cluster

- You should get familiar with Vagrant like 
    - Create VMs using Vagrantfile
    - Familiar with Vagrant commands (init,up,ssh,halt,destroy) [Vagrant Basic](https://www.vagrantup.com/docs/cli)

### 2. Installation Guide
- Install [Vargant](https://www.vagrantup.com/downloads)
- Install [VirtualBox](https://www.virtualbox.org/wiki/Download_Old_Builds_6_1)
- Install [VS Code Editor](https://code.visualstudio.com/download)
- Install [Git Client]((https://git-scm.com/downloads))
- Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

### 3. Download Vagrant Box 

We will use this box for this course. This box is pre-installed some package need for install kubernetes in this course. 
[k8s-advance-vagrant-box](https://app.vagrantup.com/btkien/boxes/ubuntu-1804-k8s-advance)

To download this box to your local machine
```
vagrant box  add  btkien/ubuntu-1804-k8s-advance --box-version 1.0.0
```

### 4. Vagrantfile
This is Vagrantfile is used in this course.You don't need to change anything.
```
# The Author : Bui Trung Kien
# This Vagrantfile is used in Kubernetes-Advance-Course 
# Do not share it without permission.


# -*- mode: ruby -*-
 # vi: set ft=ruby :
 Vagrant.configure("2") do |config|
  config.vm.box = "btkien/ubuntu-1804-k8s-advance"
  config.vm.box_version = "1.0.0"
  config.ssh.username = 'aen'
  config.vm.box_check_update = false

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.vm.provider :virtualbox do |v|
    v.memory = 2048
    v.cpus = 2
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  config.vm.define "c1-cp1" do |master|
    master.vm.box_check_update = false
    master.vm.hostname = "c1-cp1"
    master.vm.network :private_network, ip: "172.16.94.10"
  end
  (1..3).each do |i|
    config.vm.define "c1-node#{i}" do |node|
      node.vm.box_check_update = false
      node.vm.hostname = "c1-node#{i}"
      node.vm.network :private_network, ip: "172.16.94.1#{i}"
    end
  end
  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo swapoff -a
  #   sudo systemctl restart kubelet
  # SHELL
end
```
#### Vagrantfile for c1-storage 

```
# -*- mode: ruby -*-
 # vi: set ft=ruby :
 Vagrant.configure("2") do |config|
  config.vm.box = "btkien/ubuntu-1804-k8s-advance"
  config.vm.box_version = "1.0.0"
  config.ssh.username = 'aen'
  config.vm.box_check_update = false

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.vm.provider :virtualbox do |v|
    v.memory = 2048
    v.cpus = 1
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  config.vm.define "c1-storage" do |master|
    master.vm.box_check_update = false
    master.vm.hostname = "c1-storage"
    master.vm.network :private_network, ip: "172.16.94.5"
  end
end
```