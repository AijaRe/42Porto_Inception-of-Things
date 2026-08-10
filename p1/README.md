# Part 1 — K3s & Vagrant

This section walks you through spinning up the two-node K3s cluster defined in `p1`.

## Prerequisites

Make sure the following tools are installed on your host machine before proceeding:

| Tool | Purpose |
| :--- | :--- |
| [VirtualBox](https://www.virtualbox.org/) | Hypervisor that runs the VMs |
| [Vagrant](https://www.vagrantup.com/) | Automates VM provisioning |

---

## Usage

### 1 — Enter the `p1` directory

From the project root, navigate into `p1`:

```bash
cd p1
```

### 2 — Boot the VMs

Start and provision both virtual machines with:

```bash
vagrant up
```

Vagrant will:
1. Download the **`generic/alma9`** base box (AlmaLinux 9) if not already cached.
2. Create and configure two VMs:
   - **`gamado-xS`** — K3s Server node at `192.168.56.110` (1 CPU / 1 GB RAM)
   - **`gamado-xSW`** — K3s Worker/Agent node at `192.168.56.111` (1 CPU / 1 GB RAM)

### 3 — Verify the VMs are running

```bash
vagrant status
```

You should see both machines in a `running` state.

### 4 — SSH into a VM

```bash
# Connect to the server node
vagrant ssh gamado-xS

# Connect to the worker node
vagrant ssh gamado-xSW
```

### 5 — Tear down

To stop the VMs without destroying them:

```bash
vagrant halt
```

To destroy them completely and free disk space:

```bash
vagrant destroy -f
```

---

## Verification Commands

Once inside a VM (`vagrant ssh gamado-xS` or `vagrant ssh gamado-xSW`), use the commands below to confirm the setup matches the subject requirements.

### Memory — `free -h`

Confirms each VM has ~1 GB of RAM allocated.

```
               total        used        free      shared  buff/cache   available
Mem:           949Mi       337Mi       607Mi       5.0Mi       153Mi       612Mi
Swap:          2.0Gi          0B       2.0Gi
```

> **Why does 1024 MB show as 949 MiB?**
> When VirtualBox allocates 1024 MB to a guest, the VM's kernel reserves a portion upfront for low-level hardware operations (PCI devices, video memory, kernel structures). Linux only reports what remains.
> The ~75 MiB gap also reflects the unit difference: `free -h` reports in **MiB** (1 MiB = 1,048,576 bytes), while VirtualBox allocates in **MB** (1 MB = 1,000,000 bytes). The rest is consumed by the virtual BIOS and kernel before the OS even starts.


### CPU — `lscpu`

Confirms each VM has exactly **1 CPU**.

```
Architecture:            x86_64
CPU(s):                  1
  On-line CPU(s) list:   0
Vendor ID:               GenuineIntel
  Model name:            Intel(R) Core(TM) i7-7500U CPU @ 2.70GHz
    Thread(s) per core:  1
    Core(s) per socket:  1
    Socket(s):           1
Virtualization features:
  Hypervisor vendor:     KVM
  Virtualization type:   full
```

### Network — `ifconfig`

Confirms each VM has the correct dedicated IP on `eth1`.

**Server (`gamado-xS`)** — expected `192.168.56.110`:

```
eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.56.110  netmask 255.255.255.0  broadcast 192.168.56.255
        inet6 fe80::a00:27ff:fe7d:113c  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:7d:11:3c  txqueuelen 1000  (Ethernet)
```

**Worker (`gamado-xSW`)** — expected `192.168.56.111`:

```
eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.56.111  netmask 255.255.255.0  broadcast 192.168.56.255
        inet6 fe80::a00:27ff:fecd:8e7  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:cd:08:e7  txqueuelen 1000  (Ethernet)
```

### K3s node IP — `sudo kubectl get nodes -o wide`

`ifconfig` only confirms the IP is assigned at the OS level. It does **not** tell you which IP K3s actually registered for the node — and these can differ.

VirtualBox VMs always have a first interface (`eth0`) dedicated to NAT (`10.0.2.15`), used for host internet access. If K3s is not explicitly told which interface to bind to, it picks the first one it finds — typically the NAT interface — and registers that IP with the cluster. The result is nodes that appear healthy but are unreachable between each other over the private network, breaking inter-node communication.

Run this **inside the server node** (`vagrant ssh gamado-xS`) to verify K3s bound to the private network IP, not the NAT one:

```bash
sudo k3s kubectl get nodes -o wide
```

Expected output — `INTERNAL-IP` must match the private network addresses:

```
NAME        STATUS   ROLES           AGE   VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION         CONTAINER-RUNTIME
gamado-xs   Ready    control-plane   ...   v1.36.3+k3s1   192.168.56.110   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-29-amd64        containerd://2.3.2-k3s2
gamado-xsw  Ready    <none>          ...   v1.36.3+k3s1   192.168.56.111   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-29-amd64        containerd://2.3.2-k3s2
```

> **What to watch for:** if `INTERNAL-IP` shows `10.0.2.15` instead of `192.168.56.x`, K3s bound to the NAT interface. Fix this by passing `--node-ip` and `--bind-address` to the K3s install command (already applied in `scripts/server_setup.sh`).

### Controller Mode Verification (`gamado-xS`)

To confirm the server node is running in **controller/server mode**:

1. **Node Role** — `sudo kubectl get nodes -o wide`  
   Confirms `gamado-xS` has the `control-plane` role:
   ```
   NAME        STATUS   ROLES           INTERNAL-IP
   gamado-xS   Ready    control-plane   192.168.56.110
   ```

2. **Process & Service** — `ps aux | grep k3s` / `sudo systemctl cat k3s`  
   Confirms K3s runs the `server` command:
   ```
   ExecStart=/usr/local/bin/k3s server '--node-ip=192.168.56.110' '--bind-address=192.168.56.110'
   ```

3. **API Listening Port** — `sudo ss -tlnp | grep 6443`  
   Confirms `k3s-server` is listening for agent/client connections on port `6443` at `192.168.56.110`:
   ```
   LISTEN 0 4096 192.168.56.110:6443 0.0.0.0:* users:(("k3s-server",...))
   ```

