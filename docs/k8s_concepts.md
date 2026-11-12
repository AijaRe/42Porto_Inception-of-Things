# Kubernetes

A reference document explaining the core concepts of **K8s**, **K3s**, **K3d** and Kubernetes primitives.

---

## Index

- [1. What is Kubernetes (K8s)?](#1-what-is-kubernetes-k8s)
  - [What about Docker Compose?](#what-about-docker-compose)
- [2. Why is it called K8s?](#2-why-is-it-called-k8s)
- [3. What is K3s?](#3-what-is-k3s)
  - [Key Characteristics:](#key-characteristics)
  - [Server and Agent Modes](#server-and-agent-modes)
  - [How an Agent Joins the Cluster](#how-an-agent-joins-the-cluster)
  - [Bundled Components Disabled in p1](#bundled-components-disabled-in-p1)
- [4. What is K3d?](#4-what-is-k3d)
- [5. Relationship & Hierarchy (K8s, K3s, K3d)](#5-relationship--hierarchy-k8s-k3s-k3d)
- [6. Core K8s Building Blocks & Mental Model](#6-core-k8s-building-blocks--mental-model)
  - [6.1 Cluster](#61-cluster)
  - [6.2 Node](#62-node)
    - [What Runs on Each Node](#what-runs-on-each-node)
  - [6.3 Pod](#63-pod)
  - [6.4 ReplicaSet](#64-replicaset)
  - [6.5 Deployment & Rollout Management](#65-deployment--rollout-management)
    - [Rolling Updates:](#rolling-updates)
  - [6.6 Networking & Service Types Deep-Dive](#66-networking--service-types-deep-dive)
    - [Pod Networking & CNI](#pod-networking--cni)
    - [Pod Networking Between Nodes in K3s: Flannel](#pod-networking-between-nodes-in-k3s-flannel)
    - [Choosing Flannel's Interface: --flannel-iface](#choosing-flannels-interface---flannel-iface)
    - [Services](#services)
    - [Service Types Used in This Project](#service-types-used-in-this-project)
    - [How a Service Finds Its Pods: Selector, port and targetPort](#how-a-service-finds-its-pods-selector-port-and-targetport)
  - [6.7 Ingress](#67-ingress)
    - [Ingress vs Ingress Controller](#ingress-vs-ingress-controller)
    - [How Traffic Reaches Traefik: servicelb](#how-traffic-reaches-traefik-servicelb)
    - [The Host Header and the Default Rule](#the-host-header-and-the-default-rule)
    - [Full Request Flow in p2](#full-request-flow-in-p2)
- [7. What is a K8s Manifest?](#7-what-is-a-k8s-manifest)
  - [Core Manifest Fields:](#core-manifest-fields)
    - [Matching kind and apiVersion](#matching-kind-and-apiversion)
  - [End-to-End Example from p2 (Deployment + Service + Ingress)](#end-to-end-example-from-p2-deployment--service--ingress)
- [8. How Everything Works Together](#8-how-everything-works-together)
  - [Request Flow](#request-flow)
  - [Physical / Virtual Infrastructure View](#physical--virtual-infrastructure-view)
- [9. Essential kubectl Commands](#9-essential-kubectl-commands)
  - [Productivity Tip](#productivity-tip)
  - [Kubeconfig: How kubectl Finds the Cluster](#kubeconfig-how-kubectl-finds-the-cluster)
  - [Declarative Operations](#declarative-operations)
  - [Inspection & Debugging](#inspection--debugging)
  - [Rollout Status](#rollout-status)
- [10. Summary Cheat Sheet](#10-summary-cheat-sheet)
- [11. Concepts Progression in Inception-of-Things](#11-concepts-progression-in-inception-of-things)
- [12. Next Steps](#12-next-steps)
- [13. References & Resources](#13-references--resources)

---

## 1. What is Kubernetes (K8s)?

**Kubernetes** (K8s) runs containers across a group of machines, the **cluster**. You describe the desired state in YAML (which image, how many copies, how to reach them) and K8s keeps the cluster matching it: it restarts crashed containers, spreads traffic between copies and replaces old versions with new ones without downtime.

### What about Docker Compose?

Docker Compose also starts several containers from a YAML file, but only on **one machine**, and it does not watch them afterwards. K8s manages them across **many machines** and keeps correcting them. Compose suits local development; K8s suits running services that must stay up.

---

## 2. Why is it called K8s?

K8s is a numeronym. The name **"Kubernetes"** starts with a **K**, ends with an **s** and has **8 letters in between**.

---

## 3. What is K3s?

Standard K8s is extremely powerful, but it is large, complex and resource-heavy (often consuming several gigabytes of RAM just for control plane components).

**K3s** is a lightweight, fully compliant Kubernetes distribution.

[k3s installation](https://docs.k3s.io/installation/configuration)

### Key Characteristics:
- **100% K8s-compatible**: Uses the exact same `kubectl` commands and YAML manifests.
- **Lightweight footprint**: Packaged as a single binary under 100 MB with low memory usage.
- **Simplified Setup**: Strips out legacy cloud-provider drivers and external dependencies.
- **Use Cases**: Ideal for learning, local development, labs, edge devices (e.g., Raspberry Pi) and Vagrant virtual machines.

### Server and Agent Modes

K3s ships as **one single binary**. The same `k3s` program plays two different roles depending on the command it is started with:

| Mode | Command | Role in the cluster | In p1 |
|---|---|---|---|
| **Server** | `k3s server` | Runs the control plane: the API, the scheduler, the controllers and the cluster database. It also runs workloads, like any node. | `gamado-xS` |
| **Agent** | `k3s agent` | Only runs workloads. It receives pods from the server and keeps them running. It has no control plane. | `gamado-xSW` |

The installer (`curl -sfL https://get.k3s.io | sh -`) decides the mode from its environment:
- If `K3S_URL` is **not** set, it installs a **server** (systemd unit `k3s`).
- If `K3S_URL` **is** set, it installs an **agent** (systemd unit `k3s-agent`) that connects to that URL.

> **Defense tip**: `sudo systemctl cat k3s` on the server shows `k3s server ...`, and `sudo systemctl cat k3s-agent` on the worker shows `k3s agent ...`. This is the proof of each node's mode.

### How an Agent Joins the Cluster

An agent needs two pieces of information to join:

1. **Where the server is**: `K3S_URL=https://192.168.56.110:6443`. Port **6443** is the Kubernetes API port. Every component, `kubectl` included, talks to the cluster through it.
2. **A secret proving it is allowed to join**: the **node token**, generated by the server at `/var/lib/rancher/k3s/server/node-token`.

The token looks like `K10<hash>::server:<secret>`. The `<hash>` is a fingerprint of the cluster's certificate authority, so the agent can also check it is talking to the right server and not an impostor.

The join flow in p1:

```text
gamado-xS (server)                              gamado-xSW (agent)
──────────────────                              ──────────────────
1. installs k3s server
2. generates node-token
3. copies it to /vagrant/k3s-token  ───────►   4. waits until /vagrant/k3s-token exists
                                                5. installs k3s agent with
                                                   K3S_URL + K3S_TOKEN
7. accepts it and adds the node     ◄───────    6. connects to 192.168.56.110:6443
```

The token travels through the Vagrant **synced folder** (`/vagrant`), shared by both VMs. See [Vagrant: Sharing Files Between VMs](./vagrant.md#sharing-files-between-vms-the-synced-folder).

### Bundled Components Disabled in p1

K3s installs some extra components by default. The p1 server script turns three of them off with `--disable=...`:

| Component | What it does | Why it is disabled in p1 |
|---|---|---|
| **Traefik** | Ingress controller: routes external HTTP traffic to Services by hostname or path. | p1 exposes no application. |
| **servicelb** (Klipper) | Implements `LoadBalancer` Services on bare metal, where no cloud load balancer exists. | No Service is exposed in p1. |
| **metrics-server** | Collects CPU/RAM usage of nodes and pods for `kubectl top` and autoscaling. | Not required by the subject. |

Each of them runs as pods that consume memory. With only **1 GB of RAM per VM**, removing them leaves more room for the cluster itself.

---

## 4. What is K3d?

While **K3s** runs directly on a VM or physical node, **K3d** runs K3s nodes inside **Docker containers**.

```text
Traditional VM Approach:
Virtual Machine ──> Install K3s

K3d Containerized Approach:
Docker Engine ──> K3d Wrapper ──> K3s Cluster in Container
```

Create a multi-node K8s cluster in seconds:
```bash
k3d cluster create
```

---

## 5. Relationship & Hierarchy (K8s, K3s, K3d)

```text
                      Kubernetes (K8s)
                       │
           Lightweight │
          Distribution ▼
                      K3s
                       │
       Runs inside     │
     Docker Containers ▼
                      K3d
```

---

## 6. Core K8s Building Blocks & Mental Model

Think of K8s as a hierarchy:

```text
Cluster
├── Node
│   ├── Pod
│   │   └── Container(s)
│   └── Pod
└── Node
    └── Pod
```

### 6.1 Cluster
The entire K8s environment consisting of one or more physical servers or VMs working together. In this project:
- **Server VM**: Manages the cluster (Control Plane)
- **Worker VM**: Runs user workloads & applications

*Analogy: If K8s is a company, the cluster is the entire company.*

---

### 6.2 Node
A physical server, VM, or cloud instance belonging to the cluster.
- `Server VM` → Control Plane Node
- `Worker VM` → Worker Node

Check nodes with:
```bash
kubectl get nodes
```

#### What Runs on Each Node

| Component | Runs on | Role |
|---|---|---|
| **kube-apiserver** | Server | Front door of the cluster. Every request (`kubectl`, agents, controllers) goes through it on port `6443`. |
| **Datastore** | Server | Stores the whole cluster state. Standard K8s uses **etcd**. A single K3s server uses **SQLite** by default (`/var/lib/rancher/k3s/server/db/`). |
| **kube-scheduler** | Server | Decides on which node each new pod should run. |
| **kube-controller-manager** | Server | Runs the control loops that keep reality equal to the desired state (e.g., recreates a crashed pod of a Deployment). |
| **kubelet** | Every node | The node's local agent. It receives pods assigned to its node and makes the container runtime start them. |
| **containerd** | Every node | The container runtime that actually pulls images and runs containers. |
| **kube-proxy** | Every node | Programs network rules so that Service IPs reach the right pods. |
| **Flannel** | Every node | The CNI: gives each pod an IP and connects pods across nodes. |

In standard K8s each of these is a separate process. **K3s packs them all into the single `k3s` binary**, which is a big part of why it is so light. That is why `ps` on a K3s node shows `k3s server` or `k3s agent`, and not a list of separate components.

> **Note**: in K3s the server is also a regular node: it has a kubelet and can run pods. The agent, on the other hand, never runs the control plane components.

*Analogy: Each node is an office building in the company.*

---

### 6.3 Pod
The smallest deployable unit in K8s. A Pod wraps one (or occasionally more helper/sidecar) containers. K8s manages Pods rather than containers directly.

- **Shared Network**: Containers in the same Pod share the same network namespace and can communicate via `localhost`.
- **Shared Storage**: Containers in the same Pod can mount and share identical volume storage.

---

### 6.4 ReplicaSet

A **ReplicaSet** keeps a fixed number of identical Pods running. It finds its Pods through a **label selector** (`spec.selector.matchLabels`): if a Pod with that label dies, it creates a new one; if there are too many, it removes one.

ReplicaSets are not written by hand in this project: each Deployment creates one.

```text
Deployment ──> ReplicaSet ──> Pod 1, Pod 2, Pod 3
```

The number of Pods comes from `replicas: N` in the Deployment manifest. In p2, `app2-deploy` has `replicas: 3`, so its ReplicaSet keeps 3 Pods running. To change it, edit the manifest and apply it again (`kubectl apply -f`).

---

### 6.5 Deployment & Rollout Management

Ensures that the desired number of Pods are running and healthy at all times, while managing application updates.

*Analogy: A safety & operations manager ensuring active instances match desired state and managing safe upgrades.*

A Deployment is declared in a manifest with `apiVersion: apps/v1` and `kind: Deployment` (see [`p2/apps/app1/app1-deployment.yaml`](../p2/apps/app1/app1-deployment.yaml)). For the other resource types `kind` can take, see [Core Manifest Fields](#core-manifest-fields).

#### Rolling Updates:
When updating a container image or configuration, Deployments execute a **Rolling Update** by default: they create a new ReplicaSet and gradually replace old Pods with new ones without service downtime. This is what happens in p3 when Argo CD switches the image from `v1` to `v2`.

Follow it live with:

```bash
kubectl rollout status deployment/<name> -n <namespace>
```

---

### 6.6 Networking & Service Types Deep-Dive

#### Pod Networking & CNI
Every Pod in K8s receives its own unique IP address. Kubernetes delegates internal cluster networking to **Container Network Interface (CNI)** plugins. K3s uses **Flannel**.

#### Pod Networking Between Nodes in K3s: Flannel

K3s uses **Flannel** as its default CNI. Flannel gives each node a range of pod IPs (e.g., `10.42.0.0/24` for the server, `10.42.1.0/24` for the worker). When a pod on one node talks to a pod on another node, Flannel wraps the packet inside a **VXLAN** tunnel (UDP port `8472`) and sends it over the network between the nodes.

#### Choosing Flannel's Interface: `--flannel-iface`

Each VirtualBox VM has two network interfaces:
- **`eth0` (NAT)**: only used to reach the internet through the host. VirtualBox gives **every** VM the same address there, `10.0.2.15`, so VMs cannot reach each other through it.
- **`eth1` (private network)**: the network that connects the VMs and the host, with one address per VM (`192.168.56.x`).

By default, Flannel builds its tunnel on the interface of the default route, which is `eth0`. The `--node-ip` flag does **not** change that: it only sets the node's `INTERNAL-IP`. Passing **`--flannel-iface=eth1`** makes Flannel use the private network.

The p2 server script sets this flag. Part 2 has a single node, so no pod traffic crosses nodes, but it keeps the cluster network on the right interface from the start.

Check which address Flannel uses on a node:

```bash
ip -d link show flannel.1 | grep -o "local [0-9.]* dev [a-z0-9]*"   # p2: local 192.168.56.110 dev eth1
```

#### Services
A **Service** provides a stable IP address, DNS entry, and load balancing for Pods whose individual IP addresses change dynamically whenever they restart or scale.

```text
External/Internal Request ──> Service ──> Pod 1, Pod 2, Pod 3
```

#### Service Types Used in This Project

1. **`ClusterIP` (Default)**:
   - Assigns a virtual IP address **internal to the cluster**.
   - Used by the three apps in p2 (`app1-svc`, `app2-svc`, `app3-svc`): only Traefik needs to reach them, from inside the cluster.
2. **`LoadBalancer`**:
   - Exposes a Service outside the cluster. On a cloud it gets an external load balancer; in K3s, **servicelb** opens the ports on the node's IP instead.
   - Used by Traefik itself, created by K3s (see [How Traffic Reaches Traefik](#how-traffic-reaches-traefik-servicelb)).

#### How a Service Finds Its Pods: Selector, `port` and `targetPort`

A Service does not list pods by name. It uses a **label selector**: every pod whose labels match becomes a backend (an *endpoint*) of the Service. In p2:

```yaml
# Service app2-svc                    # Pods created by Deployment app2-deploy
selector:                             template:
  app: app2          ◄── matches ──►    metadata:
ports:                                    labels:
- port: 80          # Service port          app: app2
  targetPort: 8080  # container port
```

- **`port`**: the port the Service listens on inside the cluster (`app2-svc:80`).
- **`targetPort`**: the port of the container the traffic is forwarded to (`8080`, where `hello-kubernetes` listens).

With `replicas: 3`, the Service has **3 endpoints** and spreads requests between them. This is visible with `kubectl describe ingress` or `kubectl get endpointslices -l kubernetes.io/service-name=app2-svc`, and by repeating a request: the pod name shown by `hello-kubernetes` changes.

When a pod dies and its Deployment recreates it with a new IP, the new pod carries the same label, so the Service picks it up automatically.

---

### 6.7 Ingress
Manages external HTTP/HTTPS traffic entering the cluster, routing browser or client requests to the correct internal Service based on hostname or URL path.

```text
Browser ──> Ingress ──> Service ──> Pod ──> Container
```

#### Ingress vs Ingress Controller

An **Ingress** is only a set of rules (a YAML object): "requests for host X go to Service Y". It does nothing by itself. An **Ingress controller** is the program that reads those rules and actually routes the traffic.

K3s ships **Traefik** as its Ingress controller. That is why Part 2 keeps Traefik enabled, while Part 1 disables it.

| Object | What it is | In p2 |
|---|---|---|
| **Ingress** | Routing rules by host and path | `app1-ingress` (holds the rules for all three apps) |
| **Ingress controller** | Program that applies the rules | Traefik pod in `kube-system` |
| **IngressClass** | Tells which controller handles an Ingress | `traefik`, marked as default class |

The p2 Ingress has no `ingressClassName`, so `kubectl get ingress` shows `CLASS <none>`. It still works because K3s registers `traefik` as the **default** IngressClass (`ingressclass.kubernetes.io/is-default-class: "true"`), and the default controller takes every Ingress without a class.

#### How Traffic Reaches Traefik: servicelb

Traefik itself runs in a pod, with a pod IP the host cannot reach. To expose it, K3s creates a Service of type **`LoadBalancer`** for Traefik. On a cloud, a `LoadBalancer` Service gets an external load balancer. On a VM there is none, so K3s uses **servicelb** (Klipper): it runs a small `svclb-traefik-*` pod on the node that opens ports `80` and `443` on the node's IP and forwards them to Traefik.

```bash
kubectl get svc -n kube-system traefik     # TYPE LoadBalancer, EXTERNAL-IP 192.168.56.110
kubectl get pods -n kube-system | grep svclb
```

#### The Host Header and the Default Rule

A browser always sends the name it was asked to open in the HTTP **`Host`** header. That is how one IP can serve several sites: Traefik reads `Host` and picks the matching rule. `curl -H "Host: app1.com" 192.168.56.110` fakes that header without needing DNS.

The p2 Ingress has three rules:

| Rule | Matches | Goes to |
|---|---|---|
| `host: app1.com` | `Host: app1.com` | `app1-svc` |
| `host: app2.com` | `Host: app2.com` | `app2-svc` |
| no `host` | anything else, including the bare IP | `app3-svc` |

A rule **without `host`** matches every host, so it acts as the fallback; `kubectl describe ingress` shows it as `*`. Kubernetes also has a dedicated field for this, **`spec.defaultBackend`**, used when no rule matches at all. Both give the same result here; `Default backend: <default>` in `kubectl describe ingress` only means that field is not set.

#### Full Request Flow in p2

```text
Host machine:  curl -H "Host: app2.com" 192.168.56.110
      │
      ▼
192.168.56.110:80 ── svclb-traefik pod (servicelb) opens port 80 on the node
      │
      ▼
Traefik (Ingress controller) ── reads Host: app2.com, matches the Ingress rule
      │
      ▼
Service app2-svc:80 ── picks one of its 3 endpoints
      │
      ▼
Pod app2-deploy-xxxxx:8080 ── hello-kubernetes answers "Hello from app2"
```

---

## 7. What is a K8s Manifest?

A **K8s Manifest** is a declarative configuration file written in **YAML** (or JSON) that tells K8s what resources to create and how to configure them.

> **Analogy**: If K8s is a construction contractor, the **Manifest** is the **architectural blueprint**. You don't instruct K8s step-by-step *how* to build something; you give it the blueprint (desired state) and K8s makes the cluster match the blueprint automatically.

### Core Manifest Fields:

Every K8s manifest relies on **4 core top-level fields**:

| Field | Purpose | Examples |
|---|---|---|
| **`apiVersion`** | Specifies which version of the K8s API is creating this object | `v1`, `apps/v1`, `networking.k8s.io/v1` |
| **`kind`** | Specifies the type of K8s resource being created | `Pod`, `ReplicaSet`, `Deployment`, `Service`, `Ingress` |
| **`metadata`** | Metadata identifying the resource | `name`, `namespace`, `labels` |
| **`spec`** | The detailed specifications of your desired state | `replicas`, `selector`, `containers`, `image`, `ports` |

#### Matching `kind` and `apiVersion`

Each `kind` belongs to a specific API group, so `apiVersion` and `kind` must match. For example, `kind: Deployment` with `apiVersion: v1` is rejected, because Deployments live in `apps/v1`.

| `kind` | `apiVersion` | Purpose | Used in |
|---|---|---|---|
| `Pod` | `v1` | Smallest deployable unit: one or more containers | — (created by Deployments) |
| `Service` | `v1` | Stable IP/DNS name in front of a set of Pods | p2 |
| `Namespace` | `v1` | Logical isolation of resources inside a cluster | p3 (`argocd`, `dev`) |
| `Deployment` | `apps/v1` | Manages ReplicaSets, rolling updates and rollbacks | p2 |
| `ReplicaSet` | `apps/v1` | Keeps N identical Pods running (usually created by a Deployment) | — (created by Deployments) |
| `StatefulSet` | `apps/v1` | Pods with stable identity and storage | — (`argocd-application-controller`, installed by Argo CD in p3) |
| `DaemonSet` | `apps/v1` | One Pod per node | — (`svclb-traefik`, created by K3s servicelb in p2) |
| `Ingress` | `networking.k8s.io/v1` | HTTP routing by host/path to Services | p2 |
| `Application` | `argoproj.io/v1alpha1` | Argo CD custom resource (CRD) syncing a Git repo to the cluster | p3 ([`wil-playground`](../p3/confs/application.yaml)) |

This list is not exhaustive: **CRDs** (Custom Resource Definitions) let tools such as Argo CD add new `kind`s to the cluster. To list every `kind` the cluster you are connected to supports, with its API group:

```bash
kubectl api-resources
```

---

### End-to-End Example from p2 (Deployment + Service + Ingress)

The manifests of `app2` in p2 show how a **Deployment**, a **Service** and an **Ingress** connect together via **names, labels and selectors**:

```yaml
# 1. Deployment (p2/apps/app2/app2-deployment.yaml)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2-deploy
  labels:
    app: app2
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
# 2. Service (p2/apps/app2/app2-service.yaml)
apiVersion: v1
kind: Service
metadata:
  name: app2-svc
spec:
  type: ClusterIP
  ports:
  - port: 80                   # Service port inside the cluster
    targetPort: 8080           # Container port inside the Pod
  selector:
    app: app2                  # Matches the Pod label above
---
# 3. Ingress (p2/ingress/ingress.yaml, rule for app2.com only)
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
            name: app2-svc     # Sends the traffic to the Service above
            port:
              number: 80
```

> **How they link together**:
> 1. **Ingress $\rightarrow$ Service**: `backend.service.name: app2-svc` matches `Service.metadata.name: app2-svc`.
> 2. **Service $\rightarrow$ Pods**: `Service.spec.selector.app: app2` matches `Deployment.spec.template.metadata.labels.app: app2`.

---

## 8. How Everything Works Together

### Request Flow
```text
Host machine (Host: app2.com)
   │
   ▼
Ingress (Host & Path Routing: app2.com /)
   │
   ▼
Service (Stable Endpoint: app2-svc:80)
   │
   ▼
Deployment (Lifecycle & Replica Manager: app2-deploy)
   │
   ▼
ReplicaSet (Pod Count & Label Matcher: app=app2, 3 replicas)
   │
   ▼
Pod (Container Wrapper & Shared Network/Storage)
   │
   ▼
Container (hello-kubernetes on port 8080)
```

### Physical / Virtual Infrastructure View
```text
Cluster
├── Server Node (Control Plane)
└── Worker Node
      └── Pod
            └── Container
```

---

## 9. Essential `kubectl` Commands

### Productivity Tip
```bash
alias k='kubectl'
```

### Kubeconfig: How `kubectl` Finds the Cluster

`kubectl` is only a client. To talk to a cluster it needs a **kubeconfig** file, which holds three things:
- **Server address**: the URL of the API (port `6443`).
- **Certificate authority**: to verify it is talking to the real cluster.
- **Credentials**: a client certificate that proves who you are (in K3s, the cluster admin).

`kubectl` looks for it in the `KUBECONFIG` environment variable, then in `~/.kube/config`.

In K3s:
- The server writes its admin kubeconfig to `/etc/rancher/k3s/k3s.yaml`.
- `/usr/local/bin/kubectl` is a link to the `k3s` binary, which reads that file by default.
- The file is readable only by root by default. The p1 script installs K3s with `K3S_KUBECONFIG_MODE="644"`, so the `vagrant` user can run `kubectl` without `sudo`.

> **Why does `kubectl` not work on the worker?** The agent never receives an admin kubeconfig: it has no `/etc/rancher/k3s/k3s.yaml`. Without it, `kubectl` does not know where the API is, nor has credentials to use it. This is by design: an agent runs pods, it does not administer the cluster.

### Declarative Operations
```bash
kubectl apply -f manifest.yaml   # Create or update resources
kubectl delete -f manifest.yaml  # Delete resources defined in manifest
```

### Inspection & Debugging
```bash
kubectl get nodes                        # List cluster nodes
kubectl get pods -o wide                 # List Pods with IP and assigned Node
kubectl get services                     # List active Services
kubectl get deployments                  # List active Deployments
kubectl get all                          # List all active resources in namespace
kubectl describe pod <pod-name>          # View detailed lifecycle events & status
kubectl edit deployment myapp-deployment # Edit live manifest directly in cluster
```

### Rollout Status
```bash
kubectl rollout status deployment/<name>                                    # Monitor a rolling update
kubectl -n argocd rollout status statefulset/argocd-application-controller  # Used by p3 setup.sh
```

---

## 10. Summary Cheat Sheet

| Concept | Think of it as |
|---|---|
| **Cluster** | The entire K8s environment |
| **Node** | A machine (VM or physical server) in the cluster |
| **Pod** | A wrapper around one or more containers (sharing network & storage) |
| **ReplicaSet** | Ensures exact count of Pod replicas via label selectors |
| **Deployment** | Manages ReplicaSets and rolling updates |
| **Service** | Stable entry point for Pods (`ClusterIP` for the apps, `LoadBalancer` for Traefik) |
| **Ingress** | Routes external HTTP/HTTPS traffic into internal Services |
| **CNI** | Cluster networking plugin assigning Pod IPs (Flannel in K3s) |
| **Manifest** | YAML blueprint defining desired cluster state |
| **K3s / K3d** | Lightweight K8s distribution / K3s running inside Docker containers |
| **K3s server / agent** | Same binary: control plane + workloads / workloads only |
| **Node token** | Secret an agent presents to join the cluster |
| **Kubeconfig** | File telling `kubectl` where the API is and which credentials to use |
| **Ingress controller** | Program that applies Ingress rules (Traefik in K3s) |
| **IngressClass** | Links an Ingress to the controller that handles it |
| **servicelb** | K3s implementation of `LoadBalancer` Services on bare metal / VMs |

---

## 11. Concepts Progression in Inception-of-Things

The 42 School **Inception-of-Things (IoT)** project builds up DevOps expertise sequentially:

1. **Containers & Virtualization**: Docker & Vagrant VM provisioning
2. **Cluster Topology**: Master/Server Node vs. Worker Node setup
3. **Core K8s Primitives**: Pods, ReplicaSets, Services, and Deployments
4. **Traffic Management**: Ingress Controllers and Host-based HTTP routing
5. **GitOps & Continuous Deployment**: Declarative sync with Argo CD & Git repositories

---

## 12. Next Steps

Concepts this project does not need, but that come right after it, in the order of this document.

**Local clusters** ([4](#4-what-is-k3d)). Besides K3d, **Minikube** runs a local cluster, in a VM or a container.

**Nodes** ([6.2](#62-node)). `kubectl` talks to the API; on a node, `crictl` goes one level lower and inspects the containers that containerd runs.

**Scaling** ([6.4](#64-replicaset)). Here the number of Pods is fixed in the manifest (`replicas: 3`). `kubectl scale` changes it on the fly, and a **HorizontalPodAutoscaler** (HPA) changes it automatically based on CPU or memory, which needs the metrics-server that p1 disables.

**Rollback** ([6.5](#65-deployment--rollout-management)). When a new version breaks, `kubectl rollout undo` returns a Deployment to its previous ReplicaSet. With GitOps the usual way is to revert the commit and let Argo CD sync.

**Networking** ([6.6](#66-networking--service-types-deep-dive)). K3s ships Flannel, but other CNIs such as **Calico** or **Cilium** add network policies and observability. For Services, the apps here use `ClusterIP` behind Traefik; a `NodePort` Service opens a port (30000-32767) on every node without an Ingress, and on bare metal **MetalLB** gives `LoadBalancer` Services real IPs, a role servicelb plays in K3s.

**Manifests** ([7](#7-what-is-a-k8s-manifest)). The apps take their settings from `env` in the manifest. A **ConfigMap** moves that configuration out of the Deployment, and a **Secret** does the same for passwords and tokens. Pods here keep no data; a database would need a **PersistentVolume** to survive restarts.

---

## 13. References & Resources

- **Kubernetes Documentation - Concepts**: [https://kubernetes.io/docs/concepts/](https://kubernetes.io/docs/concepts/)
- **Pod Overview**: [https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/)
- **Kubernetes Tools Installation**: [https://kubernetes.io/docs/tasks/tools/](https://kubernetes.io/docs/tasks/tools/)
- **K3s Documentation**: [https://docs.k3s.io/](https://docs.k3s.io/)
- **K3d Documentation**: [https://k3d.io/](https://k3d.io/)
- **K3s Architecture (server vs agent)**: [https://docs.k3s.io/architecture](https://docs.k3s.io/architecture)
- **K3s Server CLI flags**: [https://docs.k3s.io/cli/server](https://docs.k3s.io/cli/server)
- **K3s Agent CLI flags**: [https://docs.k3s.io/cli/agent](https://docs.k3s.io/cli/agent)
- **K3s Tokens**: [https://docs.k3s.io/cli/token](https://docs.k3s.io/cli/token)
- **K3s Packaged Components (Traefik, servicelb, metrics-server)**: [https://docs.k3s.io/installation/packaged-components](https://docs.k3s.io/installation/packaged-components)
- **K3s Networking (Flannel)**: [https://docs.k3s.io/networking/basic-network-options](https://docs.k3s.io/networking/basic-network-options)
- **K3s Cluster Access (kubeconfig)**: [https://docs.k3s.io/cluster-access](https://docs.k3s.io/cluster-access)
- **Kubernetes Components**: [https://kubernetes.io/docs/concepts/overview/components/](https://kubernetes.io/docs/concepts/overview/components/)
- **Kubeconfig Files**: [https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)
- **Well-Known Labels (`node-role.kubernetes.io`)**: [https://kubernetes.io/docs/reference/labels-annotations-taints/](https://kubernetes.io/docs/reference/labels-annotations-taints/)
- **Service**: [https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/)
- **Deployments**: [https://kubernetes.io/docs/concepts/workloads/controllers/deployment/](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- **Ingress**: [https://kubernetes.io/docs/concepts/services-networking/ingress/](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- **Ingress Controllers**: [https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
- **K3s Networking Services (Traefik, servicelb)**: [https://docs.k3s.io/networking/networking-services](https://docs.k3s.io/networking/networking-services)
- **Traefik Kubernetes Ingress Provider**: [https://doc.traefik.io/traefik/providers/kubernetes-ingress/](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
