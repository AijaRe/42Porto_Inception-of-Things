# Part 1 — K3s & Vagrant

This section walks you through spinning up the two-node K3s cluster defined in `p1`.

## Prerequisites

Make sure the following tools are installed on your host machine before proceeding:

| Tool | Purpose |
| :--- | :--- |
| [VirtualBox](https://www.virtualbox.org/) | Hypervisor that runs the VMs |
| [Vagrant](https://www.vagrantup.com/) | Automates VM provisioning |

## 1 — Enter the `p1` directory

From the project root, navigate into `p1`:

```bash
cd p1
```

## 2 — Boot the VMs

Start and provision both virtual machines with:

```bash
vagrant up
```

Vagrant will:
1. Download the **`generic/alma9`** base box (AlmaLinux 9) if not already cached.
2. Create and configure two VMs:
   - **`gamado-xS`** — K3s Server node at `192.168.56.110` (1 CPU / 1 GB RAM)
   - **`gamado-xSW`** — K3s Worker/Agent node at `192.168.56.111` (1 CPU / 1 GB RAM)

## 3 — Verify the VMs are running

```bash
vagrant status
```

You should see both machines in a `running` state.

## 4 — SSH into a VM (optional)

```bash
# Connect to the server node
vagrant ssh gamado-xS

# Connect to the worker node
vagrant ssh gamado-xSW
```

## 5 — Tear down

To stop the VMs without destroying them:

```bash
vagrant halt
```

To destroy them completely and free disk space:

```bash
vagrant destroy -f
```
