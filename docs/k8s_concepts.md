# Kubernetes

A reference document explaining the core concepts of **K8s**, **K3s**, **K3d** and Kubernetes primitives.

---

## Index

- [1. What is Kubernetes (K8s)?](#1-what-is-kubernetes-k8s)
  - [What about Docker Compose?](#what-about-docker-compose)
- [2. K3s](#2-k3s)
  - [Server and Agent Modes](#server-and-agent-modes)
  - [How an Agent Joins the Cluster](#how-an-agent-joins-the-cluster)
  - [Bundled Components Disabled in p1](#bundled-components-disabled-in-p1)
- [3. K3d](#3-k3d)
- [4. Cluster and Nodes](#4-cluster-and-nodes)
  - [What Runs on Each Node](#what-runs-on-each-node)
- [5. Pods, ReplicaSets and Deployments](#5-pods-replicasets-and-deployments)
  - [ReplicaSet](#replicaset)
  - [Deployment and Rolling Updates](#deployment-and-rolling-updates)
- [6. Networking](#6-networking)
  - [Pod Networking Between Nodes in K3s: Flannel](#pod-networking-between-nodes-in-k3s-flannel)
  - [Choosing Flannel's Interface: --flannel-iface](#choosing-flannels-interface---flannel-iface)
  - [Services](#services)
  - [How a Service Finds Its Pods: Selector, port and targetPort](#how-a-service-finds-its-pods-selector-port-and-targetport)
- [7. Ingress](#7-ingress)
  - [Ingress vs Ingress Controller](#ingress-vs-ingress-controller)
  - [How Traffic Reaches Traefik: servicelb](#how-traffic-reaches-traefik-servicelb)
  - [The Host Header and the Default Rule](#the-host-header-and-the-default-rule)
  - [Full Request Flow in p2](#full-request-flow-in-p2)
- [8. Manifests](#8-manifests)
  - [Matching kind and apiVersion](#matching-kind-and-apiversion)
  - [End-to-End Example from p2](#end-to-end-example-from-p2)
- [9. kubectl](#9-kubectl)
  - [kubectl vs systemctl](#kubectl-vs-systemctl)
  - [Kubeconfig: How kubectl Finds the Cluster](#kubeconfig-how-kubectl-finds-the-cluster)
  - [Useful Commands](#useful-commands)
- [10. Cheat Sheet](#10-cheat-sheet)
- [11. Next Steps](#11-next-steps)
- [12. References](#12-references)

---

## 1. What is Kubernetes (K8s)?

**Kubernetes** (K8s) runs containers across a group of machines, the **cluster**. You describe the desired state in YAML files called **manifests** (which image, how many copies, how to reach them) and K8s keeps the cluster matching it: it restarts crashed containers, spreads traffic between copies and replaces old versions with new ones without downtime. "K8s" is a numeronym: K, eight letters, s.

### What about Docker Compose?

Docker Compose also starts several containers from a YAML file, but only on **one machine**, and it does not watch them afterwards. K8s manages them across **many machines** and keeps correcting them. Compose suits local development; K8s suits running services that must stay up.

---

## 2. K3s

Standard K8s needs several gigabytes of RAM just for its control plane. **K3s** is a lightweight, fully compatible distribution: the same `kubectl` and the same manifests, packed in a single binary of under 100 MB. That is what lets the project run a cluster on VMs with 1 GB of RAM.

### Server and Agent Modes

The same `k3s` binary has two roles. A **server** (`k3s server`) runs the control plane (API, scheduler, controllers, database) and also runs Pods. An **agent** (`k3s agent`) only runs Pods it receives from the server. In p1, `gamado-xS` is the server and `gamado-xSW` the agent.

The installer (`curl -sfL https://get.k3s.io | sh -`) picks the mode from its environment: without `K3S_URL` it installs a server (systemd unit `k3s`); with `K3S_URL` it installs an agent (unit `k3s-agent`) that connects to that URL. `sudo systemctl cat k3s` or `sudo systemctl cat k3s-agent` shows which mode each node runs.

### How an Agent Joins the Cluster

An agent needs to know **where the server is** (`K3S_URL=https://192.168.56.110:6443`, port 6443 being the Kubernetes API) and a **node token** proving it may join. The server generates the token at `/var/lib/rancher/k3s/server/node-token`. Its format, `K10<hash>::server:<secret>`, includes a fingerprint of the cluster's certificate authority, so the agent can also check it reached the right server.

In p1, the token travels through the Vagrant [synced folder](./vagrant.md#sharing-files-between-vms-the-synced-folder):

```text
gamado-xS (server)                              gamado-xSW (agent)
1. installs k3s server
2. generates node-token
3. copies it to /vagrant/k3s-token  ───────►   4. waits until /vagrant/k3s-token exists
                                                5. installs k3s agent with K3S_URL + K3S_TOKEN
7. accepts it and adds the node     ◄───────    6. connects to 192.168.56.110:6443
```

### Bundled Components Disabled in p1

K3s installs extra components by default, each running as Pods that use memory. With 1 GB per VM and no application to expose, the p1 server script turns three of them off with `--disable=...`: **Traefik** (the Ingress controller, see [Ingress](#7-ingress)), **servicelb** (exposes `LoadBalancer` Services on a VM) and **metrics-server** (CPU/RAM usage for `kubectl top`). p2 keeps Traefik and servicelb, since it exposes its apps through them.

---

## 3. K3d

**K3d** runs K3s nodes inside **Docker containers** instead of VMs. A whole cluster starts in seconds with `k3d cluster create`, which is why p3 uses it. The hierarchy is: K8s → K3s (a lightweight distribution) → K3d (K3s in Docker).

In p3, the cluster `argonauts` is created with `--port "8080:80@loadbalancer"`, so port 8080 on the host reaches port 80 inside the cluster through K3d's load balancer container.

---

## 4. Cluster and Nodes

A **cluster** is the set of machines working together; each machine is a **node**. In p1 the cluster has two nodes: the server (control plane) and the worker. `kubectl get nodes` lists them.

### What Runs on Each Node

| Component | Runs on | Role |
|---|---|---|
| **kube-apiserver** | Server | Front door of the cluster on port `6443`. Every request goes through it. |
| **Datastore** | Server | Cluster state. Standard K8s uses etcd; a single K3s server uses SQLite (`/var/lib/rancher/k3s/server/db/`). |
| **kube-scheduler** | Server | Picks the node for each new Pod. |
| **kube-controller-manager** | Server | Control loops that keep reality equal to the desired state. |
| **kubelet** | Every node | Starts the Pods assigned to its node through the container runtime. |
| **containerd** | Every node | Pulls images and runs containers. |
| **kube-proxy** | Every node | Network rules that send Service IPs to the right Pods. |
| **Flannel** | Every node | Gives each Pod an IP and connects Pods across nodes. |

In standard K8s these are separate processes. K3s packs them all into the `k3s` binary, so `ps` on a node shows only `k3s server` or `k3s agent`. The server is also a regular node that can run Pods; the agent never runs the control plane.

---

## 5. Pods, ReplicaSets and Deployments

A **Pod** is the smallest unit K8s manages: one container (sometimes a few) sharing the same network, so they talk over `localhost`. Pods are not created by hand in this project; a Deployment creates them through a ReplicaSet.

```text
Deployment ──> ReplicaSet ──> Pod 1, Pod 2, Pod 3
```

### ReplicaSet

A **ReplicaSet** keeps a fixed number of identical Pods running. It finds them by **label selector** (`spec.selector.matchLabels`): if a Pod with that label dies, it creates another. The number comes from `replicas` in the Deployment; in p2, `app2-deploy` has `replicas: 3`.

### Deployment and Rolling Updates

A **Deployment** (`apps/v1`, see [`app1-deployment.yaml`](../p2/apps/app1/app1-deployment.yaml)) owns the ReplicaSet and handles updates. When the image or configuration changes, it creates a new ReplicaSet and replaces old Pods with new ones gradually, without downtime: a **rolling update**. That is what happens in p3 when Argo CD switches the image from `v1` to `v2`. `kubectl rollout status deployment/<name> -n <namespace>` follows it live.

---

## 6. Networking

Every Pod gets its own IP. Networking between Pods is delegated to a **CNI** (Container Network Interface) plugin; K3s uses **Flannel**.

### Pod Networking Between Nodes in K3s: Flannel

Flannel gives each node a range of Pod IPs (e.g., `10.42.0.0/24` for the server, `10.42.1.0/24` for the worker). When a Pod talks to a Pod on another node, Flannel wraps the packet in a **VXLAN** tunnel (UDP `8472`) between the nodes.

### Choosing Flannel's Interface: `--flannel-iface`

Each VirtualBox VM has two interfaces: `eth0` (NAT), used only to reach the internet and with the same address `10.0.2.15` on every VM, and `eth1` (private network), with one address per VM (`192.168.56.x`). Flannel builds its tunnel on the default route's interface, `eth0`, and `--node-ip` does not change that. **`--flannel-iface=eth1`** does. The p2 script sets it; with a single node no Pod traffic crosses nodes, but the network starts on the right interface.

```bash
ip -d link show flannel.1 | grep -o "local [0-9.]* dev [a-z0-9]*"   # p2: local 192.168.56.110 dev eth1
```

### Services

Pod IPs change every time a Pod is recreated. A **Service** gives a set of Pods a stable IP and DNS name and spreads requests between them. The project uses two types: **`ClusterIP`** (the default, reachable only inside the cluster) for the three p2 apps, which only Traefik needs to reach, and **`LoadBalancer`** for Traefik itself, which K3s exposes on the node's IP through [servicelb](#how-traffic-reaches-traefik-servicelb).

### How a Service Finds Its Pods: Selector, `port` and `targetPort`

A Service does not list Pods by name. Every Pod whose labels match its **selector** becomes an endpoint. `port` is where the Service listens (`app2-svc:80`); `targetPort` is the container port the traffic goes to (`8080`, where `hello-kubernetes` listens).

```yaml
# Service app2-svc                    # Pods created by Deployment app2-deploy
selector:                             template:
  app: app2          ◄── matches ──►    metadata:
ports:                                    labels:
- port: 80                                  app: app2
  targetPort: 8080
```

With `replicas: 3`, `app2-svc` has 3 endpoints (`kubectl get endpointslices -l kubernetes.io/service-name=app2-svc`), and repeating a request shows a different Pod name. A recreated Pod carries the same label, so the Service picks it up automatically.

---

## 7. Ingress

An **Ingress** routes HTTP traffic from outside the cluster to Services, by hostname or path.

### Ingress vs Ingress Controller

The Ingress is only a set of rules in YAML; it does nothing by itself. The **Ingress controller** is the program that reads the rules and routes the traffic. K3s ships **Traefik** as its controller, which is why p2 keeps it and p1 disables it. The p2 Ingress (`app1-ingress`, holding the rules of the three apps) has no `ingressClassName`, so `kubectl get ingress` shows `CLASS <none>`; it still works because K3s marks `traefik` as the **default IngressClass**.

### How Traffic Reaches Traefik: servicelb

Traefik runs in a Pod the host cannot reach, so K3s exposes it with a `LoadBalancer` Service. A cloud would provide a load balancer; on a VM, K3s uses **servicelb**: a small `svclb-traefik-*` Pod that opens ports 80 and 443 on the node's IP and forwards them to Traefik.

```bash
kubectl get svc -n kube-system traefik     # TYPE LoadBalancer, EXTERNAL-IP 192.168.56.110
kubectl get pods -n kube-system | grep svclb
```

### The Host Header and the Default Rule

A browser sends the name it opens in the HTTP **`Host`** header, so one IP can serve several sites: Traefik reads `Host` and picks the matching rule. `curl -H "Host: app1.com" 192.168.56.110` fakes that header without DNS. The p2 Ingress sends `app1.com` to `app1-svc`, `app2.com` to `app2-svc`, and has a third rule **without `host`**, which matches anything else (including the bare IP) and sends it to `app3-svc`. `kubectl describe ingress` shows that rule as `*`; its `Default backend: <default>` line refers to the separate `spec.defaultBackend` field, which is not set.

### Full Request Flow in p2

```text
curl -H "Host: app2.com" 192.168.56.110
  ▼
192.168.56.110:80     svclb-traefik Pod (servicelb) opens port 80 on the node
  ▼
Traefik               reads Host: app2.com, matches the Ingress rule
  ▼
Service app2-svc:80   picks one of its 3 endpoints
  ▼
Pod :8080             hello-kubernetes answers "Hello from app2"
```

---

## 8. Manifests

A **manifest** is a YAML file describing the desired state of a resource; K8s makes the cluster match it. Every manifest has four top-level fields: **`apiVersion`** (API group and version), **`kind`** (resource type), **`metadata`** (`name`, `namespace`, `labels`) and **`spec`** (the desired state itself).

### Matching `kind` and `apiVersion`

Each `kind` belongs to an API group, so the two must match: `kind: Deployment` with `apiVersion: v1` is rejected, because Deployments live in `apps/v1`. `kubectl api-resources` lists every `kind` the cluster supports. Tools can add their own kinds through **CRDs** (Custom Resource Definitions), as Argo CD does with `Application`.

| `kind` | `apiVersion` | Used in |
|---|---|---|
| `Service` | `v1` | p2 apps |
| `Namespace` | `v1` | p3 (`argocd`, `dev`) |
| `Deployment` | `apps/v1` | p2 apps |
| `StatefulSet` | `apps/v1` | created by Argo CD (`argocd-application-controller`) |
| `DaemonSet` | `apps/v1` | created by K3s servicelb (`svclb-traefik`) |
| `Ingress` | `networking.k8s.io/v1` | p2 |
| `Application` | `argoproj.io/v1alpha1` | p3 ([`application.yaml`](../p3/confs/application.yaml)) |

### End-to-End Example from p2

The `app2` manifests show how the three resources link: the Ingress points to the Service by **name**, and the Service finds the Pods by **label**.

```yaml
# p2/apps/app2/app2-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2-deploy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2              # Label carried by every Pod
    spec:
      containers:
      - name: app2-container
        image: paulbouwer/hello-kubernetes:1.10.1
        ports:
        - containerPort: 8080
        env:
        - name: MESSAGE
          value: "Hello from app2"
---
# p2/apps/app2/app2-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: app2-svc               # Name used by the Ingress
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: app2                  # Matches the Pod label
---
# p2/ingress/ingress.yaml (app2.com rule only)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app1-ingress
spec:
  rules:
  - host: app2.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-svc     # Matches the Service name
            port:
              number: 80
```

---

## 9. kubectl

### kubectl vs systemctl

`kubectl` looks like `systemctl` for K8s, and the idea is close: a client that asks a manager (systemd / the K8s control plane) to run things, described in files (unit files / manifests). The difference is that `systemctl start` is an order the local systemd executes once, while `kubectl apply` only records the desired state in the API server, possibly on another machine; the controllers and kubelets then keep the whole cluster matching it, even after `kubectl` exits. In this project the two stack up: `systemctl` manages the `k3s` service, and K3s manages the Pods.

### Kubeconfig: How `kubectl` Finds the Cluster

`kubectl` is only a client. It needs a **kubeconfig** file with the API address (port 6443), the cluster's certificate authority and the user's credentials, read from `$KUBECONFIG` or `~/.kube/config`.

On a K3s server, the admin kubeconfig is `/etc/rancher/k3s/k3s.yaml`, and `/usr/local/bin/kubectl` is a link to `k3s`, which reads that file. It is root-only by default; the scripts install K3s with `K3S_KUBECONFIG_MODE="644"` so the `vagrant` user needs no `sudo`. The agent never gets this file, which is why `kubectl` does not work on the p1 worker: it runs Pods, it does not administer the cluster. In p3, `setup.sh` writes the K3d cluster's kubeconfig to `~/.kube/config` with `k3d kubeconfig get`.

### Useful Commands

The p1 and p2 server scripts add `alias k=kubectl` with completion.

```bash
kubectl apply -f manifest.yaml           # Create or update resources
kubectl delete -f manifest.yaml          # Delete them
kubectl get nodes -o wide                # Nodes with their IPs
kubectl get pods -o wide                 # Pods with IP and node
kubectl get all -n <namespace>           # Everything in a namespace
kubectl describe pod <pod-name>          # Details and events (first stop when a Pod fails)
kubectl rollout status deployment/<name> # Follow a rolling update
```

---

## 10. Cheat Sheet

| Concept | Think of it as |
|---|---|
| **Cluster / Node** | The set of machines / one machine in it |
| **K3s server / agent** | Same binary: control plane + Pods / Pods only |
| **Node token** | Secret an agent presents to join the cluster |
| **K3d** | K3s running inside Docker containers |
| **Pod** | One or more containers sharing a network |
| **ReplicaSet** | Keeps N Pods running, found by label |
| **Deployment** | Owns the ReplicaSet and does rolling updates |
| **CNI** | Gives Pods IPs and connects them (Flannel in K3s) |
| **Service** | Stable IP/name in front of Pods (`ClusterIP`, `LoadBalancer`) |
| **Ingress / controller** | Routing rules by host / program applying them (Traefik) |
| **servicelb** | K3s way of exposing `LoadBalancer` Services on a VM |
| **Manifest** | YAML describing the desired state |
| **Kubeconfig** | Where the API is and which credentials `kubectl` uses |

---

## 11. Next Steps

Concepts this project does not need, but that come right after it, in the order of this document.

**K3d** ([3](#3-k3d)). Besides K3d, **Minikube** runs a local cluster, in a VM or a container.

**Nodes** ([4](#4-cluster-and-nodes)). `kubectl` talks to the API; on a node, `crictl` goes one level lower and inspects the containers that containerd runs.

**Scaling** ([ReplicaSet](#replicaset)). Here the number of Pods is fixed in the manifest. `kubectl scale` changes it on the fly, and a **HorizontalPodAutoscaler** (HPA) changes it automatically based on CPU or memory, which needs the metrics-server that p1 disables.

**Rollback** ([Deployment](#deployment-and-rolling-updates)). When a new version breaks, `kubectl rollout undo` returns a Deployment to its previous ReplicaSet. With GitOps the usual way is to revert the commit and let Argo CD sync.

**Networking** ([6](#6-networking)). Other CNIs such as **Calico** or **Cilium** add network policies and observability. A `NodePort` Service opens a port (30000-32767) on every node without an Ingress, and on bare metal **MetalLB** gives `LoadBalancer` Services real IPs, the role servicelb plays in K3s.

**Manifests** ([8](#8-manifests)). The apps take their settings from `env`. A **ConfigMap** moves that configuration out of the Deployment, and a **Secret** does the same for passwords and tokens. A database would also need a **PersistentVolume** to keep its data across restarts.

---

## 12. References

- **Kubernetes Concepts**: [https://kubernetes.io/docs/concepts/](https://kubernetes.io/docs/concepts/)
- **Kubernetes Components**: [https://kubernetes.io/docs/concepts/overview/components/](https://kubernetes.io/docs/concepts/overview/components/)
- **Deployments**: [https://kubernetes.io/docs/concepts/workloads/controllers/deployment/](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- **Service**: [https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/)
- **Ingress**: [https://kubernetes.io/docs/concepts/services-networking/ingress/](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- **Kubeconfig Files**: [https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)
- **K3s Documentation**: [https://docs.k3s.io/](https://docs.k3s.io/)
- **K3s Architecture (server vs agent)**: [https://docs.k3s.io/architecture](https://docs.k3s.io/architecture)
- **K3s Server / Agent flags**: [https://docs.k3s.io/cli/server](https://docs.k3s.io/cli/server), [https://docs.k3s.io/cli/agent](https://docs.k3s.io/cli/agent)
- **K3s Tokens**: [https://docs.k3s.io/cli/token](https://docs.k3s.io/cli/token)
- **K3s Packaged Components**: [https://docs.k3s.io/installation/packaged-components](https://docs.k3s.io/installation/packaged-components)
- **K3s Networking (Flannel, Traefik, servicelb)**: [https://docs.k3s.io/networking/basic-network-options](https://docs.k3s.io/networking/basic-network-options), [https://docs.k3s.io/networking/networking-services](https://docs.k3s.io/networking/networking-services)
- **K3s Cluster Access**: [https://docs.k3s.io/cluster-access](https://docs.k3s.io/cluster-access)
- **K3d Documentation**: [https://k3d.io/](https://k3d.io/)
- **Traefik Kubernetes Ingress**: [https://doc.traefik.io/traefik/providers/kubernetes-ingress/](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
