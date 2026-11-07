# Vagrant Guide

This guide is for a dev who wants to understand what Vagrant is,
why it is useful and how to use it to create repeatable virtual machines for
local labs and development.

## Index

- [1. What Vagrant Does](#1-what-vagrant-does)
- [2. Important Vocabulary](#2-important-vocabulary)
- [3. What I Need To Install](#3-what-i-need-to-install)
- [4. First Useful Commands](#4-first-useful-commands)
- [5. My First Vagrant Project](#5-my-first-vagrant-project)
- [6. A Minimal Vagrantfile](#6-a-minimal-vagrantfile)
- [7. Using VirtualBox Without Opening A GUI Window](#7-using-virtualbox-without-opening-a-gui-window)
- [8. Configuring CPU, Memory And Name](#8-configuring-cpu-memory-and-name)
- [9. Networking Basics](#9-networking-basics)
  - [Port Forwarding](#port-forwarding)
  - [Private Network](#private-network)
  - [Public Network / Bridge](#public-network--bridge)
- [10. Installing Apache With A Shell Provisioner](#10-installing-apache-with-a-shell-provisioner)
- [11. Inline Shell Provisioning](#11-inline-shell-provisioning)
- [12. Provisioning With Ansible](#12-provisioning-with-ansible)
- [13. Multiple VMs In One Vagrantfile](#13-multiple-vms-in-one-vagrantfile)
  - [Sharing Files Between VMs: The Synced Folder](#sharing-files-between-vms-the-synced-folder)
- [14. Example Lab: Load Balancer And Web Servers](#14-example-lab-load-balancer-and-web-servers)
- [15. Snapshots](#15-snapshots)
- [16. Packaging Your Own Box](#16-packaging-your-own-box)
- [17. Troubleshooting Notes](#17-troubleshooting-notes)
  - [Vagrant Cannot Find box.ovf](#vagrant-cannot-find-boxovf)
  - [VirtualBox Requires A License Agreement](#virtualbox-requires-a-license-agreement)
  - [rsync Could Not Be Found](#rsync-could-not-be-found)
  - [CentOS 7 Yum Mirrors Fail](#centos-7-yum-mirrors-fail)
  - [Validate The Vagrantfile](#validate-the-vagrantfile)
  - [Check VirtualBox VMs](#check-virtualbox-vms)
- [18. Helpful Aliases](#18-helpful-aliases)
- [19. Suggested Learning Path](#19-suggested-learning-path)
- [20. Quick Reference](#20-quick-reference)
- [21. Beginner Mental Model](#21-beginner-mental-model)
- [22. References](#22-references)

## 1. What Vagrant Does

Vagrant is a tool for creating and managing VMs from code.

Instead of creating a VM manually, clicking through VirtualBox screens, logging
in and installing packages by hand, I describe the VM in a file named
`Vagrantfile`.

Then I run:

```bash
vagrant up
```

Vagrant reads the `Vagrantfile`, talks to a virtualization provider such as
VirtualBox, creates the VM, configures networking and can install software
automatically.

The main benefit is repeatability:

- Every dev can create the same environment.
- Labs can be destroyed and recreated quickly.
- Setup steps are written down as code.
- I can test changes without damaging my host machine.

## 2. Important Vocabulary

**Host machine**

My real computer. For example, my Linux laptop.

**Guest machine**

The VM created by Vagrant.

**Provider**

The software that actually runs the VM. Common providers include VirtualBox and VMware. In these notes, VirtualBox is the provider.

**Box**

A base image used to create a VM. Examples:

```bash
ubuntu/bionic64
ubuntu/jammy64
kalilinux/rolling
centos/7
```

A box is similar to an OS template.

**Vagrantfile**

The configuration file that describes the VM. It tells Vagrant which box to
use, how much CPU and memory to assign, what network to configure, and what
provisioning scripts to run.

**Provisioning**

Automatic configuration after the VM is created. Provisioning can install
packages, create files, start services and configure the system.

Common provisioners:

- Shell scripts
- Ansible
- Chef
- Puppet

## 3. What I Need To Install

For a basic setup with VirtualBox:

1. Install VirtualBox.
2. Install Vagrant.
3. Confirm my system details if needed:

```bash
cat /etc/*-release
uname -mrs
```

Useful links:

- https://www.virtualbox.org/wiki/Downloads
- https://developer.hashicorp.com/vagrant/install
- https://developer.hashicorp.com/vagrant/docs
- https://portal.cloud.hashicorp.com/vagrant/discover

## 4. First Useful Commands

Check available commands:

```bash
vagrant --help
vagrant list-commands
```

Work with a VM:

```bash
vagrant init
vagrant validate
vagrant up
vagrant status
vagrant ssh
vagrant provision
vagrant reload
vagrant halt
vagrant suspend
vagrant resume
vagrant destroy
```

Important difference:

- `vagrant halt` shuts down the VM.
- `vagrant suspend` pauses the VM state.
- `vagrant destroy` deletes the VM.

## 5. My First Vagrant Project

Create a folder for the VM:

```bash
mkdir ubuntu-vagrant-lab
cd ubuntu-vagrant-lab
```

Initialize a Vagrant project:

```bash
vagrant init ubuntu/jammy64
```

This creates a file named `Vagrantfile`.

Start the VM:

```bash
vagrant up
```

Connect to the VM:

```bash
vagrant ssh
```

Inside the VM, try:

```bash
whoami
hostname
ip a
```

Exit the VM:

```bash
exit
```

Stop the VM:

```bash
vagrant halt
```

Delete the VM when I no longer need it:

```bash
vagrant destroy
```

## 6. A Minimal Vagrantfile

A small `Vagrantfile` can look like this:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
end
```

When I run `vagrant up`, Vagrant looks for a `Vagrantfile` in the current
directory. If it does not find one, it checks parent directories.

That means I should usually run Vagrant commands from the folder that belongs
to my lab.

## 7. Using VirtualBox Without Opening A GUI Window

Sometimes VirtualBox opens a VM window when I run `vagrant up`.

If I want to work only through the CLI, set `vb.gui = false`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
  end
end
```

Then reload the VM:

```bash
vagrant reload
```

## 8. Configuring CPU, Memory And Name

Provider-specific settings go inside the provider block:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.cpus = 2
    vb.memory = 2048
    vb.name = "ubuntu-dev-vm"
  end
end
```

After booting, check inside the VM:

```bash
vagrant ssh
nproc
free -h
```

Disk resizing usually needs a plugin, for example:

```bash
vagrant plugin install vagrant-disksize
```

Then in the `Vagrantfile`:

```ruby
config.disksize.size = "24GB"
```

## 9. Networking Basics

Vagrant networking has three common options:

- Port forwarding
- Private network
- Public network, also called bridged networking

### Port Forwarding

Port forwarding exposes a guest port on the host machine.

Example:

```ruby
config.vm.network "forwarded_port", guest: 80, host: 8080
```

If Apache is running inside the VM on port 80, I can open this on the host:

```text
http://localhost:8080
```

### Private Network

A private network creates a host-only network between my host and the VM.

Example with DHCP:

```ruby
config.vm.network "private_network", type: "dhcp"
```

Example with static IP:

```ruby
config.vm.network "private_network", ip: "192.168.56.10"
```

This is useful when my host needs to reach the VM, but other devices on my
real network do not need access.

### Public Network / Bridge

A public network makes the VM appear like another device on my real network.

Example:

```ruby
config.vm.network "public_network"
```

If Vagrant asks which interface to bridge to, choose my active network
interface, for example Wi-Fi or Ethernet.

I can also specify it:

```ruby
config.vm.network "public_network", bridge: "wlp3s0"
```

Use this carefully. Other devices on my network may be able to reach the VM.

## 10. Installing Apache With A Shell Provisioner

Create a new folder:

```bash
mkdir ubuntu-apache
cd ubuntu-apache
vagrant init ubuntu/jammy64
```

Create a script named `apache.sh`:

```bash
#!/bin/bash

sudo apt update
sudo apt install apache2 -y
sudo systemctl enable apache2
sudo systemctl start apache2
```

Use it from the `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.provision "shell", path: "apache.sh"
end
```

Start the VM:

```bash
vagrant up
```

Open this on the host:

```text
http://192.168.56.10
```

If I change the script and want to run provisioning again:

```bash
vagrant provision
```

Or reload and provision:

```bash
vagrant reload --provision
```

## 11. Inline Shell Provisioning

For tiny commands, I can write provisioning directly in the `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.provision "shell", inline: <<-SHELL
    echo "Hello from provisioning"
    date > /etc/vagrant_provisioned_at
  SHELL
end
```

Use external scripts when the setup grows. They are easier to read and reuse.

## 12. Provisioning With Ansible

Ansible is useful when provisioning becomes more complex.

Example `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
  end
end
```

Example `playbook.yml`:

```yaml
---
- name: Install tools on Ubuntu
  hosts: all
  become: true

  tasks:
    - name: Install Apache
      apt:
        name: apache2
        state: present
        update_cache: true
```

Then run:

```bash
vagrant up
```

If the VM already exists:

```bash
vagrant provision
```

## 13. Multiple VMs In One Vagrantfile

I can create several VMs from one `Vagrantfile`.

Example with three Kali VMs:

```ruby
Vagrant.configure("2") do |config|
  (1..3).each do |i|
    config.vm.define "vm_#{i}" do |node|
      node.vm.box = "kalilinux/rolling"
      node.vm.box_version = "2025.1.0"
      node.vm.network "public_network", bridge: "wlp3s0"
    end
  end

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.cpus = 1
  end
end
```

Start all VMs:

```bash
vagrant up
```

Connect to one VM:

```bash
vagrant ssh vm_1
vagrant ssh vm_2
vagrant ssh vm_3
```

Stop all VMs:

```bash
vagrant halt
```

Stop only one VM:

```bash
vagrant halt vm_1
```

### Sharing Files Between VMs: The Synced Folder

By default, Vagrant mounts the project directory (the folder that contains the `Vagrantfile`) inside every VM at **`/vagrant`**.

```text
Host:  ~/Inception-of-Things/p1/   ◄──── same files ────►   VM: /vagrant/
```

This is called a **synced folder**. Since all VMs of a `Vagrantfile` mount the same host folder, it is also the simplest way to pass files **between** VMs:

1. One VM writes a file to `/vagrant/`.
2. The file appears in the project folder on the host.
3. The other VM sees it in its own `/vagrant/`.

In p1, this is how the K3s **node token** goes from the server to the worker: the server copies it to `/vagrant/k3s-token` and the worker waits for that file before joining. This is also why `k3s-token` appears in the `p1` folder on the host and is listed in `.gitignore`: it is a secret and must not be committed.

How the folder is synced depends on the box and provider. It can be a live share (VirtualBox shared folders, NFS) or a one-time copy (`rsync`). With `rsync`, changes only travel when Vagrant syncs, which matters if a VM is waiting for a file written by another. In p1, `mount` shows `type vboxsf`: a live VirtualBox shared folder, so the token written by the server appears immediately for the worker.

Check it inside a VM:

```bash
ls /vagrant
mount | grep vagrant
```

Configure or disable it in the `Vagrantfile`:

```ruby
config.vm.synced_folder ".", "/vagrant"                  # default behavior
config.vm.synced_folder "./shared", "/home/vagrant/shared" # custom folder
config.vm.synced_folder ".", "/vagrant", disabled: true  # disable it
```

## 14. Example Lab: Load Balancer And Web Servers

A more advanced lab can create:

- Two web servers running Apache.
- Two load balancer VMs using IPVS.

The web servers need stable IP addresses because the load balancer must know
where to send traffic.

Example structure:

```text
lab-ipvs/
  Vagrantfile
  httpd_1.sh
  httpd_2.sh
  lb_ipvsadm.sh
```

Example `Vagrantfile` idea:

```ruby
Vagrant.configure("2") do |config|
  (1..2).each do |i|
    config.vm.define "web_#{i}" do |web|
      web.vm.box = "centos/7"
      web.vm.network "public_network", bridge: "wlp3s0", ip: "192.168.0.12#{i}"
      web.vm.provision "shell", path: "httpd_#{i}.sh"
    end
  end

  (1..2).each do |i|
    config.vm.define "lb_ipvsadm_#{i}" do |lb|
      lb.vm.box = "centos/7"
      lb.vm.network "public_network", bridge: "wlp3s0", ip: "192.168.0.12#{i + 2}"
      lb.vm.provision "shell", path: "lb_ipvsadm.sh"
    end
  end
end
```

IPVS is a Linux kernel feature for load balancing network traffic. In this lab,
the load balancer receives HTTP traffic on a virtual IP and distributes requests
to the backend Apache servers.

Important note: CentOS 7 reached end of life on June 30, 2024. Old CentOS 7
labs may fail because normal package mirrors are no longer available. If I
continue using CentOS 7 for a lab, I may need to point yum to the CentOS
vault repositories.

## 15. Snapshots

Snapshots let me save and restore VM state.

Check snapshot commands:

```bash
vagrant snapshot -h
```

Save a snapshot:

```bash
vagrant snapshot save clean-install
```

Restore a snapshot:

```bash
vagrant snapshot restore clean-install
```

This is useful before testing risky changes.

## 16. Packaging Your Own Box

After configuring a VM, I can package it as a reusable box.

From the project folder:

```bash
vagrant package --output my-custom-vm.box
```

Add it to my local Vagrant boxes:

```bash
vagrant box add my-custom-vm my-custom-vm.box
```

Use it in a new project:

```bash
mkdir test-custom-box
cd test-custom-box
vagrant init my-custom-vm
vagrant up
```

## 17. Troubleshooting Notes

### Vagrant Cannot Find `box.ovf`

Sometimes a box may contain an OVF file with a different name than Vagrant
expects.

Example problem:

```text
Vagrant expects: box.ovf
Actual file: kali-linux-2025.2-virtualbox-amd64.ovf
```

One possible workaround is creating a symbolic link inside the unpacked box
folder:

```bash
cd ~/.vagrant.d/boxes/kalilinux-VAGRANTSLASH-rolling/2025.2.0/amd64/virtualbox/
ln -s kali-linux-2025.2-virtualbox-amd64.ovf box.ovf
```

If that still fails, try an older box version:

```bash
vagrant init kalilinux/rolling --box-version 2025.1.0
vagrant up
```

### VirtualBox Requires A License Agreement

If manual import shows an EULA error, I may need:

```bash
VBoxManage import path/to/box.ovf --vsys 0 --eula accept
```

### `rsync` Could Not Be Found

If Vagrant says:

```text
"rsync" could not be found on my PATH
```

Install rsync on the host:

```bash
sudo apt install rsync
```

Then retry:

```bash
vagrant up
```

### CentOS 7 Yum Mirrors Fail

CentOS 7 is end of life, so old provisioning scripts may fail during `yum
install`.

For old labs only, I can redirect repositories to the vault:

```bash
sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
sudo yum clean all
sudo yum makecache
```

For new labs, prefer a supported distribution when possible.

### Validate The Vagrantfile

If Vagrant behaves strangely, first check syntax:

```bash
vagrant validate
```

### Check VirtualBox VMs

List VirtualBox VMs:

```bash
VBoxManage list vms
```

Only unregister/delete VMs when I am sure I no longer need them:

```bash
VBoxManage unregistervm VM_ID --delete
```

## 18. Helpful Aliases

I can add shortcuts to `~/.bashrc`:

```bash
alias vs="vagrant up && vagrant ssh"
alias vd="vagrant destroy -f"
```

Reload the shell:

```bash
source ~/.bashrc
```

Then use:

```bash
vs
vd
```

Use destructive aliases carefully. `vd` deletes the VM without asking.

## 19. Suggested Learning Path

1. Create one Ubuntu VM.
2. SSH into it with `vagrant ssh`.
3. Stop, start, suspend, resume and destroy it.
4. Add CPU and memory settings.
5. Add a private network.
6. Install Apache using a shell provisioner.
7. Re-run provisioning with `vagrant provision`.
8. Create two or three VMs from one `Vagrantfile`.
9. Try Ansible provisioning.
10. Take and restore a snapshot.
11. Package a VM into a custom box.

## 20. Quick Reference

```bash
# Create a Vagrantfile
vagrant init ubuntu/jammy64

# Validate syntax
vagrant validate

# Start VM
vagrant up

# SSH into VM
vagrant ssh

# Show status
vagrant status

# Re-run provisioning
vagrant provision

# Reload after changing Vagrantfile
vagrant reload

# Stop VM
vagrant halt

# Pause VM
vagrant suspend

# Resume VM
vagrant resume

# Delete VM
vagrant destroy

# List local boxes
vagrant box list

# Remove old boxes
vagrant box prune
```

## 21. Beginner Mental Model

Think of Vagrant like this:

```text
Vagrantfile + Box + Provider = Repeatable VM
```

The `Vagrantfile` is my recipe.

The box is my starting operating system.

The provider is the engine that runs the VM.

Provisioning is the part that turns a plain VM into the environment I actually
want.

Once that clicks, Vagrant becomes much less mysterious: I am not manually
building machines anymore. I am writing down how machines should be built.

## 22. References

- **Vagrant Documentation**: [https://developer.hashicorp.com/vagrant/docs](https://developer.hashicorp.com/vagrant/docs)
- **Vagrantfile**: [https://developer.hashicorp.com/vagrant/docs/vagrantfile](https://developer.hashicorp.com/vagrant/docs/vagrantfile)
- **Multi-Machine**: [https://developer.hashicorp.com/vagrant/docs/multi-machine](https://developer.hashicorp.com/vagrant/docs/multi-machine)
- **Private Networks**: [https://developer.hashicorp.com/vagrant/docs/networking/private_network](https://developer.hashicorp.com/vagrant/docs/networking/private_network)
- **Synced Folders**: [https://developer.hashicorp.com/vagrant/docs/synced-folders](https://developer.hashicorp.com/vagrant/docs/synced-folders)
- **Shell Provisioner**: [https://developer.hashicorp.com/vagrant/docs/provisioning/shell](https://developer.hashicorp.com/vagrant/docs/provisioning/shell)
- **VirtualBox Provider**: [https://developer.hashicorp.com/vagrant/docs/providers/virtualbox](https://developer.hashicorp.com/vagrant/docs/providers/virtualbox)
- **VirtualBox Manual**: [https://www.virtualbox.org/manual/](https://www.virtualbox.org/manual/)
