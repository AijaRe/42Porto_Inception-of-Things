# Part 2 — K3s & Three Simple Applications

This section walks you through a single-node K3s cluster running three web applications, reachable on `192.168.56.110` and routed by the HTTP `Host` header through an **Ingress**.

## Index

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Usage](#usage)
  - [1 — Enter the p2 directory](#1--enter-the-p2-directory)
  - [2 — Boot the VM](#2--boot-the-vm)
  - [3 — Re-apply the manifests only](#3--re-apply-the-manifests-only)
  - [4 — SSH into the VM](#4--ssh-into-the-vm)
  - [5 — Tear down](#5--tear-down)
- [Testing From the Host](#testing-from-the-host)
  - [The 3 replicas of app2](#the-3-replicas-of-app2)
  - [In a browser (optional)](#in-a-browser-optional)
- [Verification Commands](#verification-commands)
  - [Node — k get nodes -o wide](#node--k-get-nodes--o-wide)
  - [Applications — k get all](#applications--k-get-all)
  - [Ingress — k get ingress / k describe ingress](#ingress--k-get-ingress--k-describe-ingress)
  - [Ingress controller — Traefik and servicelb](#ingress-controller--traefik-and-servicelb)
- [Concepts Behind Part 2](#concepts-behind-part-2)
- [Materials](#materials)
- [References](#references)

## Prerequisites

| Tool | Purpose |
| :--- | :--- |
| [VirtualBox](https://www.virtualbox.org/) | Hypervisor that runs the VM |
| [Vagrant](https://www.vagrantup.com/) | Automates VM provisioning |

> **Part 1 must be stopped** (`cd ../p1 && vagrant halt`). Both parts use the IP `192.168.56.110`.

---

## Project Structure

```text
p2/
├── Vagrantfile                  # One VM: arepsaS, 192.168.56.110
├── scripts/
│   ├── server_setup.sh          # Installs K3s in server mode
│   └── deploy_apps.sh           # Applies all Kubernetes manifests
├── apps/
│   ├── app1/
│   │   ├── app1-deployment.yaml # 1 replica,  "Hello from app1"
│   │   └── app1-service.yaml
│   ├── app2/
│   │   ├── app2-deployment.yaml # 3 replicas, "Hello from app2"
│   │   └── app2-service.yaml
│   └── app3/
│       ├── app3-deployment.yaml # 1 replica,  "Hello from app3"
│       └── app3-service.yaml
└── ingress/
    └── ingress.yaml             # app1.com → app1, app2.com → app2, anything else → app3
```

All three apps use the image `paulbouwer/hello-kubernetes`. Only the `MESSAGE` environment variable changes. The page also shows which pod answered, which makes the replicas visible.

---

## Usage

### 1 — Enter the `p2` directory

```bash
cd p2
```

### 2 — Boot the VM

```bash
vagrant up
```

Vagrant will:
1. Download the **`debian/bookworm64`** base box (Debian 12) if not already cached.
2. Create the VM **`arepsaS`** at `192.168.56.110` (2 CPU / 2 GB RAM).
3. Run the provisioner **`ServerSetup`**: install K3s in server mode, keeping Traefik as Ingress controller.
4. Run the provisioner **`DeployApps`**: apply the Deployments, Services and the Ingress.

### 3 — Re-apply the manifests only

After editing a YAML file, re-run only the deployment step:

```bash
vagrant provision --provision-with DeployApps
```

### 4 — SSH into the VM

```bash
vagrant ssh
```

### 5 — Tear down

```bash
vagrant halt        # stop the VM
vagrant destroy -f  # delete the VM
```

---

## Testing From the Host

Run these on the host machine, outside the VM. `-H "Host: ..."` sets the HTTP `Host` header, which is what a browser sends when opening `app1.com`.

```bash
curl -s -H "Host: app1.com" 192.168.56.110 | grep -i "hello from"   # Hello from app1
curl -s -H "Host: app2.com" 192.168.56.110 | grep -i "hello from"   # Hello from app2
curl -s 192.168.56.110 | grep -i "hello from"                       # Hello from app3 (default)
curl -s -H "Host: other.com" 192.168.56.110 | grep -i "hello from"  # Hello from app3 (default)
```

### The 3 replicas of app2

Repeat the request and look at the pod name: requests are spread across the 3 pods.

```bash
for i in 1 2 3 4 5 6; do curl -s -H "Host: app2.com" 192.168.56.110 | grep -A1 "pod:" | tail -1; done
```

```text
<td>app2-deploy-5947c8566-26nzf</td>
<td>app2-deploy-5947c8566-rgrnt</td>
<td>app2-deploy-5947c8566-2jjjt</td>
...
```

### In a browser (optional)

To open `http://app1.com` in a browser, the host must resolve the names to the VM. Add this line to `/etc/hosts` on the host (requires `sudo`, and remove it after the defense):

```text
192.168.56.110 app1.com app2.com
```

---

## Verification Commands

Run these inside the VM (`vagrant ssh`).

### Node — `k get nodes -o wide`

One node, `control-plane` role, `INTERNAL-IP` `192.168.56.110`.

### Applications — `k get all`

Expected: 5 pods `Running` (app2 has 3), 3 `ClusterIP` Services and 3 Deployments:

```text
NAME                          READY   UP-TO-DATE   AVAILABLE
deployment.apps/app1-deploy   1/1     1            1
deployment.apps/app2-deploy   3/3     3            3
deployment.apps/app3-deploy   1/1     1            1
```

### Ingress — `k get ingress` / `k describe ingress`

The subject hides the Ingress on purpose: it must be shown during the defense.

```text
Rules:
  Host        Path  Backends
  ----        ----  --------
  app1.com    /     app1-svc:80 (10.42.0.20:8080)
  app2.com    /     app2-svc:80 (10.42.0.18:8080,10.42.0.17:8080,10.42.0.22:8080)
  *           /     app3-svc:80 (10.42.0.21:8080)
```

- `*` is the rule without `host`: the default that sends everything else to app3.
- app2 has **3 backends**, one per replica.
- `CLASS <none>` is expected: Traefik is the default IngressClass in K3s, so it handles Ingresses without a class.

### Ingress controller — Traefik and servicelb

```bash
k get svc,pods -n kube-system | grep -E "traefik|svclb"
```

Traefik runs as a `LoadBalancer` Service with `EXTERNAL-IP` `192.168.56.110`, exposed by the `svclb-traefik` pod (servicelb).

---

## Concepts Behind Part 2

| Question | Where to read |
| :--- | :--- |
| What is the difference between an Ingress and an Ingress controller? | [Ingress vs Ingress Controller](../docs/k8s_concepts.md#ingress-vs-ingress-controller) |
| How does traffic on `192.168.56.110:80` reach Traefik? | [servicelb](../docs/k8s_concepts.md#how-traffic-reaches-traefik-servicelb) |
| How does the `Host` header choose the app? Why does app3 answer by default? | [The Host Header and the Default Rule](../docs/k8s_concepts.md#the-host-header-and-the-default-rule) |
| What is the full path of a request? | [Full Request Flow in p2](../docs/k8s_concepts.md#full-request-flow-in-p2) |
| How does a Service find its pods? What are `port` and `targetPort`? | [Selector, port and targetPort](../docs/k8s_concepts.md#how-a-service-finds-its-pods-selector-port-and-targetport) |
| How are the 3 replicas of app2 created? | [ReplicaSet](../docs/k8s_concepts.md#64-replicaset) / [Deployment](../docs/k8s_concepts.md#65-deployment--rollout-management) |
| Why does the server script use `--flannel-iface=eth1`? | [Flannel's Interface](../docs/k8s_concepts.md#choosing-flannels-interface---flannel-iface) |
| How does `--provision-with DeployApps` work? | [Named Provisioners](../docs/vagrant.md#named-provisioners) |

---

## Materials

- [The Coding Gopher - Kubernetes Deployments and Services](https://www.youtube.com/watch?v=z9nYikBIqRA)
- [IBM - What is Ingress](https://www.youtube.com/watch?v=NPFbYpb0I7w)
- [The Coding Gopher - Kubernetes Ingress](https://www.youtube.com/watch?v=uGsR9fuBVqU)

## References

- **Kubernetes Ingress**: [https://kubernetes.io/docs/concepts/services-networking/ingress/](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- **Kubernetes Service**: [https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/)
- **Kubernetes Deployments**: [https://kubernetes.io/docs/concepts/workloads/controllers/deployment/](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- **K3s Networking Services (Traefik, servicelb)**: [https://docs.k3s.io/networking/networking-services](https://docs.k3s.io/networking/networking-services)
- **hello-kubernetes image**: [https://github.com/paulbouwer/hello-kubernetes](https://github.com/paulbouwer/hello-kubernetes)
- **Vagrant Provisioning Basics**: [https://developer.hashicorp.com/vagrant/docs/provisioning/basic_usage](https://developer.hashicorp.com/vagrant/docs/provisioning/basic_usage)
