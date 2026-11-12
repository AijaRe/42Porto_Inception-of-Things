# Vagrant Guide

What Vagrant is, why it is useful and how Parts 1 and 2 of **Inception-of-Things** use it to create repeatable virtual machines.

## Index

- [1. What Vagrant Does](#1-what-vagrant-does)
- [2. Important Vocabulary](#2-important-vocabulary)
- [3. What I Need To Install](#3-what-i-need-to-install)
- [4. Essential Commands](#4-essential-commands)
- [5. The Vagrantfile](#5-the-vagrantfile)
- [6. Configuring CPU, Memory And Name](#6-configuring-cpu-memory-and-name)
- [7. Private Network](#7-private-network)
- [8. Shell Provisioning](#8-shell-provisioning)
  - [Named Provisioners](#named-provisioners)
- [9. Multiple VMs In One Vagrantfile](#9-multiple-vms-in-one-vagrantfile)
  - [Sharing Files Between VMs: The Synced Folder](#sharing-files-between-vms-the-synced-folder)
- [10. Triggers](#10-triggers)
- [11. Troubleshooting](#11-troubleshooting)
- [12. Mental Model](#12-mental-model)
- [13. References](#13-references)

## 1. What Vagrant Does

Vagrant is a tool for creating and managing VMs from code.

Instead of creating a VM manually, clicking through VirtualBox screens, logging
in and installing packages by hand, I describe the VM in a file named
`Vagrantfile`. Then I run:

```bash
vagrant up
```

Vagrant reads the `Vagrantfile`, talks to a virtualization provider such as
VirtualBox, creates the VM, configures networking and installs software
automatically.

The main benefit is repeatability:

- Every dev can create the same environment.
- Labs can be destroyed and recreated quickly.
- Setup steps are written down as code.

## 2. Important Vocabulary

| Term | Meaning | In this project |
|---|---|---|
| **Host machine** | My real computer | The machine running `vagrant up` |
| **Guest machine** | The VM created by Vagrant | `gamado-xS`, `gamado-xSW` (p1), `arepsaS` (p2) |
| **Provider** | The software that actually runs the VM | VirtualBox |
| **Box** | Base OS image used to create a VM | `debian/bookworm64` |
| **Vagrantfile** | Ruby file describing the VMs: box, CPU, memory, network and provisioning | `p1/Vagrantfile`, `p2/Vagrantfile` |
| **Provisioning** | Automatic configuration after the VM is created (install packages, start services) | Shell scripts in `scripts/` |

## 3. What I Need To Install

1. Install VirtualBox.
2. Install Vagrant.

Useful links:

- https://www.virtualbox.org/wiki/Downloads
- https://developer.hashicorp.com/vagrant/install

## 4. Essential Commands

Run them from the folder that contains the `Vagrantfile` (`p1/` or `p2/`):

```bash
vagrant validate              # Check the Vagrantfile syntax
vagrant up                    # Create, boot and provision the VMs
vagrant status                # Show the state of each VM
vagrant ssh gamado-xS         # Open a shell in one VM
vagrant provision             # Run the provisioners again
vagrant reload                # Restart after changing the Vagrantfile
vagrant halt                  # Shut down the VMs
vagrant destroy -f            # Delete the VMs
vagrant box list              # List downloaded boxes
```

Important difference:

- `vagrant halt` shuts down the VM; the disk is kept.
- `vagrant destroy` deletes the VM; the next `vagrant up` starts from scratch.

## 5. The Vagrantfile

The smallest useful `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
end
```

When I run `vagrant up`, Vagrant looks for a `Vagrantfile` in the current
directory. If it does not find one, it checks parent directories. That is why
the commands are run from `p1/` or `p2/`.

## 6. Configuring CPU, Memory And Name

Provider-specific settings go inside the provider block. From `p1/Vagrantfile`:

```ruby
server.vm.provider "virtualbox" do |vb|
  vb.name   = "gamado-xS"   # Name shown in VirtualBox
  vb.cpus   = 1
  vb.memory = 1024          # MB
end
```

p1 uses 1 CPU / 1 GB per VM, as the subject asks. p2 gives its single VM 2 CPUs / 2 GB because it runs Traefik and three apps.

Check inside the VM:

```bash
nproc
free -h
```

## 7. Private Network

A private network is a host-only network between the host and the VMs, with a
static IP per VM:

```ruby
server.vm.network "private_network", ip: "192.168.56.110"
```

Each VM then has two interfaces:

- **`eth0` (NAT)**: added by Vagrant to reach the internet. Every VM gets the same address there (`10.0.2.15`).
- **`eth1` (private network)**: one address per VM (`192.168.56.110`, `192.168.56.111`), reachable from the host and from the other VMs.

That is why the K3s scripts pin `--node-ip` and, in p2, `--flannel-iface=eth1`. See [Choosing Flannel's Interface](./k8s_concepts.md#choosing-flannels-interface---flannel-iface).

Check it inside a VM:

```bash
ip a show eth1
```

## 8. Shell Provisioning

A provisioner runs a script inside the VM after it boots:

```ruby
server.vm.provision "shell", path: "scripts/server_setup.sh"
```

The path is relative to the `Vagrantfile`. Provisioners run **in the order they are declared**, and by default only on the first `vagrant up`. Later runs need `vagrant provision` or `vagrant up --provision`.

### Named Provisioners

A provisioner can be given a **name**. This makes it possible to re-run only one step instead of all of them:

```ruby
config.vm.provision "ServerSetup", type: "shell", path: "scripts/server_setup.sh"
config.vm.provision "DeployApps",  type: "shell", path: "scripts/deploy_apps.sh"
```

```bash
vagrant provision                              # runs every provisioner again
vagrant provision --provision-with DeployApps  # runs only DeployApps
```

Part 2 uses this: after editing the YAML manifests, `vagrant provision --provision-with DeployApps` applies them again without reinstalling K3s.

## 9. Multiple VMs In One Vagrantfile

`config.vm.define` declares one VM; a `Vagrantfile` can hold several. p1 defines the server and the worker:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  config.vm.define "gamado-xS" do |server|
    server.vm.hostname = "gamado-xS"
    server.vm.network "private_network", ip: "192.168.56.110"
    server.vm.provision "shell", path: "scripts/server_setup.sh"
  end

  config.vm.define "gamado-xSW" do |worker|
    worker.vm.hostname = "gamado-xSW"
    worker.vm.network "private_network", ip: "192.168.56.111"
    worker.vm.provision "shell", path: "scripts/worker_setup.sh"
  end
end
```

Settings on `config` apply to every VM; settings on `server` / `worker` only to that one. VMs are created in the order they are defined, so the server comes up before the worker.

Most commands accept a VM name:

```bash
vagrant up                 # all VMs
vagrant ssh gamado-xSW     # one VM
vagrant halt gamado-xSW    # stop only the worker
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

In p1, this is how the K3s **node token** goes from the server to the worker: the server copies it to `/vagrant/k3s-token` and the worker waits for that file before joining. This is also why `k3s-token` appears in the `p1` folder on the host and is listed in `.gitignore`: it is a secret and must not be committed. In p2, the same folder is how `deploy_apps.sh` reads the manifests from `/vagrant/apps/`.

How the folder is synced depends on the box and provider. It can be a live share (VirtualBox shared folders, NFS) or a one-time copy (`rsync`). With `rsync`, changes only travel when Vagrant syncs, which matters if a VM is waiting for a file written by another. In p1, `mount` shows `type vboxsf`: a live VirtualBox shared folder, so the token written by the server appears immediately for the worker.

Check it inside a VM:

```bash
ls /vagrant
mount | grep vagrant
```

## 10. Triggers

A **trigger** runs code on the host before or after a Vagrant command. p1 uses one to delete the shared token when the server is destroyed, so the next `vagrant up` can never pick up a stale token:

```ruby
server.trigger.after :destroy do |t|
  t.info = "Removing stale k3s-token"
  t.ruby do
    token = File.join(__dir__, "k3s-token")
    File.delete(token) if File.exist?(token)
  end
end
```

## 11. Troubleshooting

Check the `Vagrantfile` syntax first:

```bash
vagrant validate
```

List the VMs VirtualBox knows about (useful when a VM is left behind after a failed `destroy`):

```bash
VBoxManage list vms
```

Only unregister/delete a VM when I am sure I no longer need it:

```bash
VBoxManage unregistervm VM_ID --delete
```

## 12. Mental Model

```text
Vagrantfile + Box + Provider = Repeatable VM
```

- The `Vagrantfile` is the recipe.
- The box is the starting operating system.
- The provider is the engine that runs the VM.
- Provisioning turns a plain VM into the environment I actually want.

I am not manually building machines anymore. I am writing down how machines should be built.

## 13. References

- **Vagrant Documentation**: [https://developer.hashicorp.com/vagrant/docs](https://developer.hashicorp.com/vagrant/docs)
- **Vagrantfile**: [https://developer.hashicorp.com/vagrant/docs/vagrantfile](https://developer.hashicorp.com/vagrant/docs/vagrantfile)
- **Multi-Machine**: [https://developer.hashicorp.com/vagrant/docs/multi-machine](https://developer.hashicorp.com/vagrant/docs/multi-machine)
- **Private Networks**: [https://developer.hashicorp.com/vagrant/docs/networking/private_network](https://developer.hashicorp.com/vagrant/docs/networking/private_network)
- **Synced Folders**: [https://developer.hashicorp.com/vagrant/docs/synced-folders](https://developer.hashicorp.com/vagrant/docs/synced-folders)
- **Provisioning Basics (named provisioners)**: [https://developer.hashicorp.com/vagrant/docs/provisioning/basic_usage](https://developer.hashicorp.com/vagrant/docs/provisioning/basic_usage)
- **Shell Provisioner**: [https://developer.hashicorp.com/vagrant/docs/provisioning/shell](https://developer.hashicorp.com/vagrant/docs/provisioning/shell)
- **Triggers**: [https://developer.hashicorp.com/vagrant/docs/triggers](https://developer.hashicorp.com/vagrant/docs/triggers)
- **VirtualBox Provider**: [https://developer.hashicorp.com/vagrant/docs/providers/virtualbox](https://developer.hashicorp.com/vagrant/docs/providers/virtualbox)
