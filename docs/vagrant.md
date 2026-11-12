# Vagrant Guide

What Vagrant is and how Parts 1 and 2 of **Inception-of-Things** use it to create repeatable virtual machines.

## Index

- [1. What Vagrant Does](#1-what-vagrant-does)
- [2. Vocabulary](#2-vocabulary)
- [3. Essential Commands](#3-essential-commands)
- [4. The Vagrantfile](#4-the-vagrantfile)
- [5. Private Network](#5-private-network)
- [6. Shell Provisioning](#6-shell-provisioning)
  - [Named Provisioners](#named-provisioners)
- [7. Multiple VMs](#7-multiple-vms)
  - [Sharing Files Between VMs: The Synced Folder](#sharing-files-between-vms-the-synced-folder)
- [8. Triggers](#8-triggers)
- [9. Troubleshooting](#9-troubleshooting)
- [10. Next Steps](#10-next-steps)
- [11. References](#11-references)

## 1. What Vagrant Does

Vagrant creates and manages VMs from code. Instead of clicking through VirtualBox and installing packages by hand, the VM is described in a `Vagrantfile`; `vagrant up` reads it, asks VirtualBox to create the VM, configures the network and runs the setup scripts. The result is repeatable: anyone gets the same machines, and they can be destroyed and recreated in minutes. Installing it only takes [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and [Vagrant](https://developer.hashicorp.com/vagrant/install).

## 2. Vocabulary

The **host** is the real computer; the **guest** is the VM. The **provider** is the software that runs the VM (VirtualBox here). The **box** is the base OS image (`debian/bookworm64`). **Provisioning** is the setup that runs after the VM boots, here shell scripts that install K3s. In short:

```text
Vagrantfile + Box + Provider = Repeatable VM
```

## 3. Essential Commands

Run them from the folder that holds the `Vagrantfile` (`p1/` or `p2/`). Vagrant looks for it in the current directory and then in parent directories.

```bash
vagrant validate              # Check the Vagrantfile syntax
vagrant up                    # Create, boot and provision the VMs
vagrant status                # State of each VM
vagrant ssh gamado-xS         # Shell in one VM
vagrant provision             # Run the provisioners again
vagrant reload                # Restart after changing the Vagrantfile
vagrant halt                  # Shut down (disk is kept)
vagrant destroy -f            # Delete the VMs (next up starts from scratch)
```

## 4. The Vagrantfile

The `Vagrantfile` is Ruby. It sets the box, and inside a provider block, the VirtualBox settings. From `p1/Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  config.vm.define "gamado-xS" do |server|
    server.vm.hostname = "gamado-xS"
    server.vm.provider "virtualbox" do |vb|
      vb.name   = "gamado-xS"   # Name shown in VirtualBox
      vb.cpus   = 1
      vb.memory = 1024          # MB
    end
  end
end
```

p1 uses 1 CPU and 1 GB per VM, as the subject asks; p2 gives its single VM 2 CPUs and 2 GB because it runs Traefik and three apps. `nproc` and `free -h` inside the VM confirm it.

## 5. Private Network

```ruby
server.vm.network "private_network", ip: "192.168.56.110"
```

A **private network** is a host-only network between the host and the VMs, with a fixed IP per VM. Each VM ends up with two interfaces: `eth0`, the NAT that Vagrant always adds to reach the internet (same address `10.0.2.15` on every VM), and `eth1`, the private network (`192.168.56.110`, `192.168.56.111`), reachable from the host and the other VMs. That is why the K3s scripts pin `--node-ip` and, in p2, [`--flannel-iface=eth1`](./k8s_concepts.md#choosing-flannels-interface---flannel-iface). `ip a show eth1` shows it.

## 6. Shell Provisioning

```ruby
server.vm.provision "shell", path: "scripts/server_setup.sh"
```

A shell provisioner runs a script inside the VM after boot; the path is relative to the `Vagrantfile`. Provisioners run in the order they are declared and, by default, only on the first `vagrant up`; later runs need `vagrant provision` or `vagrant up --provision`.

### Named Provisioners

Giving provisioners a name lets one run alone. p2 has two:

```ruby
config.vm.provision "ServerSetup", type: "shell", path: "scripts/server_setup.sh"
config.vm.provision "DeployApps",  type: "shell", path: "scripts/deploy_apps.sh"
```

After editing the manifests, `vagrant provision --provision-with DeployApps` applies them again without reinstalling K3s.

## 7. Multiple VMs

Each `config.vm.define` block declares one VM, so one `Vagrantfile` can hold several. p1 defines the server `gamado-xS` and the worker `gamado-xSW`, each with its hostname, IP and setup script. Settings on `config` (like the box) apply to every VM; settings inside a `define` block only to that one. VMs are created in the order they are defined, so the server comes up first. Most commands take a VM name: `vagrant ssh gamado-xSW`, `vagrant halt gamado-xSW`.

### Sharing Files Between VMs: The Synced Folder

Vagrant mounts the project folder (where the `Vagrantfile` is) inside every VM at **`/vagrant`**. Since all VMs mount the same host folder, a file one VM writes there appears for the others too.

```text
Host:  ~/Inception-of-Things/p1/   ◄──── same files ────►   VM: /vagrant/
```

In p1 this is how the K3s **node token** reaches the worker: the server copies it to `/vagrant/k3s-token` and the worker waits for that file before joining. The token is a secret, so `k3s-token` is in `.gitignore`. In p2, `deploy_apps.sh` reads the manifests from `/vagrant/apps/` the same way.

Depending on box and provider, the folder can be a live share or a one-time `rsync` copy, and with `rsync` a file written by one VM would not reach the other. In this project `mount | grep vagrant` shows `type vboxsf`: a live VirtualBox shared folder, so the token appears for the worker immediately.

## 8. Triggers

A **trigger** runs code on the host before or after a Vagrant command. p1 uses one to delete the shared token when the server is destroyed, so the next `vagrant up` never picks up a stale token:

```ruby
server.trigger.after :destroy do |t|
  t.info = "Removing stale k3s-token"
  t.ruby do
    token = File.join(__dir__, "k3s-token")
    File.delete(token) if File.exist?(token)
  end
end
```

## 9. Troubleshooting

When Vagrant behaves strangely, `vagrant validate` checks the syntax first. If a VM is left behind after a failed `destroy`, `VBoxManage list vms` shows what VirtualBox still knows, and `VBoxManage unregistervm <VM_ID> --delete` removes it (only when sure it is no longer needed).

If `vagrant up` fails with **`VERR_VMX_IN_VMX_ROOT_MODE`**, KVM is loaded and holds the CPU's virtualization extensions that VirtualBox needs. Unload it on the machine where Vagrant runs:

```bash
sudo modprobe -r kvm_intel kvm
```

If it fails with **`VERR_VMX_NO_VMX`** (VT-x is not available), Vagrant is running inside a VM that has no access to virtualization. Turn on nested virtualization for that VM from the physical computer, with the VM shut down:

```bash
VBoxManage modifyvm "<vm-name>" --nested-hw-virt on
```

## 10. Next Steps

Features this project does not need, in the order of this document.

**Commands** ([3](#3-essential-commands)). `vagrant snapshot save <name>` and `vagrant snapshot restore <name>` save and restore a VM's state, handy before a risky change. `vagrant suspend` / `resume` pause a VM instead of shutting it down.

**The Vagrantfile** ([4](#4-the-vagrantfile)). After configuring a VM, `vagrant package` turns it into a reusable box that other projects can start from. Resizing the disk needs a plugin such as `vagrant-disksize`.

**Networking** ([5](#5-private-network)). A **forwarded port** (`config.vm.network "forwarded_port", guest: 80, host: 8080`) exposes one guest port on `localhost` without a private network. A **public network** (bridge) puts the VM on the real LAN like another device, reachable by other machines.

**Provisioning** ([6](#6-shell-provisioning)). Short commands can go `inline` in the `Vagrantfile` instead of a script. When setup grows, **Ansible** (`config.vm.provision "ansible"`) replaces shell scripts with idempotent playbooks.

**Multiple VMs** ([7](#7-multiple-vms)). A Ruby loop (`(1..3).each do |i| ... end`) defines many similar VMs without repeating blocks.

## 11. References

- **Vagrant Documentation**: [https://developer.hashicorp.com/vagrant/docs](https://developer.hashicorp.com/vagrant/docs)
- **Vagrantfile**: [https://developer.hashicorp.com/vagrant/docs/vagrantfile](https://developer.hashicorp.com/vagrant/docs/vagrantfile)
- **Multi-Machine**: [https://developer.hashicorp.com/vagrant/docs/multi-machine](https://developer.hashicorp.com/vagrant/docs/multi-machine)
- **Private Networks**: [https://developer.hashicorp.com/vagrant/docs/networking/private_network](https://developer.hashicorp.com/vagrant/docs/networking/private_network)
- **Synced Folders**: [https://developer.hashicorp.com/vagrant/docs/synced-folders](https://developer.hashicorp.com/vagrant/docs/synced-folders)
- **Provisioning (named provisioners)**: [https://developer.hashicorp.com/vagrant/docs/provisioning/basic_usage](https://developer.hashicorp.com/vagrant/docs/provisioning/basic_usage)
- **Shell Provisioner**: [https://developer.hashicorp.com/vagrant/docs/provisioning/shell](https://developer.hashicorp.com/vagrant/docs/provisioning/shell)
- **Triggers**: [https://developer.hashicorp.com/vagrant/docs/triggers](https://developer.hashicorp.com/vagrant/docs/triggers)
- **VirtualBox Provider**: [https://developer.hashicorp.com/vagrant/docs/providers/virtualbox](https://developer.hashicorp.com/vagrant/docs/providers/virtualbox)
