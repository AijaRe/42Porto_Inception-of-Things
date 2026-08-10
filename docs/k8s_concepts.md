# Kubernetes

A reference document explaining the core concepts of **K8s**, **K3s** and **K3d**.

---

## 1. What is Kubernetes (K8s)?

**Kubernetes** or **K8s** is a platform for orchestrating, automating and managing containerized applications at scale.

When running hundreds of containers across multiple machines, K8s automatically handles:
- **Auto-healing**: Starts crashed containers and stops unresponsive ones.
- **Scaling**: Scales applications up or down based on load.
- **Load Balancing**: Distributes network traffic evenly across containers.
- **Zero-downtime Deployments**: Rolling updates and rollbacks without stopping service.
- **Storage & Networking**: Manages persistent volumes and internal cluster DNS.

### What about Docker Compose?

- **Docker Compose** is designed to manage multi-container applications on a **single machine** (`docker compose up`).
- **K8s** is designed to manage multi-container applications across a **cluster of multiple machines** with auto-healing, load balancing, zero-downtime updates and automated scaling.

> **Rule of thumb**: Use **Docker Compose** for quick local development on 1 machine. Use **K8s** for managing production workloads across clusters.

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
- **Use Cases**: Ideal for learning, local development, labs and edge devices (e.g., Raspberry Pi).

---

## 4. What is K3d?

While **K3s** runs directly on a VM or physical node, **K3d** takes portability a step further by running K3s nodes inside **Docker containers**.

### Architectural Comparison:

```text
Traditional VM Approach:
Virtual Machine ──> Install K3s

K3d Containerized Approach:
Docker Engine ──> K3d Wrapper ──> K3s Cluster in Container
```

### Quick Cluster Creation:
With K3d installed, creating a multi-node K8s cluster is as simple as running:
```bash
k3d cluster create
```
A complete, fully functional K8s cluster is ready in seconds without needing heavy VM images.

---

## 5. Relationship & Hierarchy (K8s, K3s, K3d)

```text
                      Kubernetes (K8s)
                             │
                  Lightweight distribution
                             │
                            K3s
                             │
          Runs K3s cluster inside Docker containers
                             │
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

### 1. Cluster
The entire K8s environment consisting of one or more physical or VMs working together. In this project:
- **Server VM**: Manages the cluster (Control Plane)
- **Worker VM**: Runs user workloads & applications

*Analogy: If K8s is a company, the cluster is the entire company.*

---

### 2. Node
A physical server, VM or cloud instance belonging to the cluster. In this project:
- `Server VM` → Node
- `Worker VM` → Node

Check nodes with:
```bash
kubectl get nodes
```

*Analogy: Each node is an office building in the company.*

---

### 3. Pod
The smallest deployable unit in K8s. A Pod wraps one (or occasionally more) Docker containers. K8s manages Pods rather than containers directly.

---

### 4. Deployment
Ensures that the desired number of Pods are running and healthy at all times. If a Pod crashes, the Deployment notices and creates a replacement Pod automatically.

*Analogy: A safety manager ensuring the required count of active instances is always maintained.*

---

### 5. Service
Provides a stable internal IP address and DNS name for Pods whose individual IP addresses change whenever they restart or scale.

```text
Service ──> Pod 1, Pod 2, Pod 3
```

*Analogy: A receptionist routing internal requests to whichever room the active workers are currently occupying.*

---

### 6. Ingress
Manages external HTTP/HTTPS traffic entering the cluster, routing browser or client requests to the correct internal Service based on hostname or URL path.

```text
Browser ──> Ingress ──> Service ──> Pod ──> Container
```

---

## 7. What is a K8s Manifest?

A **K8s Manifest** is a declarative configuration file written in **YAML** (or JSON) that tells K8s what resources to create and how to configure them.

> **Analogy**: If K8s is a construction contractor, the **Manifest** is the **architectural blueprint**. You don't instruct K8s step-by-step *how* to build something; you give it the blueprint (desired state) and K8s makes the cluster match the blueprint automatically.

### Anatomy of a K8s Manifest

Every K8s manifest relies on **4 core top-level fields**:

```yaml
apiVersion: apps/v1       # 1. Which API group and version to use
kind: Deployment          # 2. What object to create (Pod, Deployment, Service, Ingress)
metadata:                 # 3. Data to identify the object (name, labels, namespace)
  name: my-web-app
  namespace: dev
spec:                     # 4. The desired specification and configuration
  replicas: 3
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
```

### Core Manifest Fields:

| Field | Purpose | Examples |
|---|---|---|
| **`apiVersion`** | Specifies which version of the K8s API is creating this object | `v1`, `apps/v1`, `networking.k8s.io/v1` |
| **`kind`** | Specifies the type of K8s resource being created | `Pod`, `Deployment`, `Service`, `Ingress` |
| **`metadata`** | Metadata identifying the resource | `name`, `namespace`, `labels` |
| **`spec`** | The detailed specifications of your desired state | `replicas`, `containers`, `image`, `ports` |

---

## 8. How Everything Works Together

### Request Flow
```text
Internet
   │
   ▼
Ingress (Host & Path Routing)
   │
   ▼
Service (Stable Endpoint & Load Balancer)
   │
   ▼
Deployment (Lifecycle & Replica Manager)
   │
   ▼
Pod (Container Wrapper)
   │
   ▼
Container (e.g., Nginx, Web App, Redis)
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

| Command | Action |
|---|---|
| `kubectl get nodes` | Show cluster nodes |
| `kubectl get pods` | Show running Pods |
| `kubectl get services` | Show active Services |
| `kubectl get deployments` | Show active Deployments |
| `kubectl apply -f app.yaml` | Apply a YAML configuration manifest |
| `kubectl delete -f app.yaml` | Delete resources specified in a YAML manifest |

---

## 10. Summary Cheat Sheet

| Concept | Think of it as |
|---|---|
| **Cluster** | The entire K8s environment |
| **Node** | A machine (VM or server) in the cluster |
| **Pod** | A wrapper around one or more containers |
| **Deployment** | Keeps the desired number of Pods running |
| **Service** | A stable way to reach Pods inside the cluster |
| **Ingress** | Routes external HTTP/HTTPS traffic into the cluster |
| **Manifest** | A YAML blueprint defining your desired cluster resources |
| **k3s** | Lightweight K8s distribution ideal for Vagrant VMs |

---

## 11. Concepts Progression in Inception-of-Things

The project builds up DevOps expertise sequentially:

1. **Containers & Virtualization**: Docker & Vagrant VM provisioning
2. **Cluster Topology**: Master/Server Node vs. Worker Node setup
3. **Core K8s Primitives**: Pods, Services and Deployments
4. **Traffic Management**: Ingress Controllers and Host-based HTTP routing
5. **GitOps & Continuous Deployment**: Declarative sync with Argo CD & Git repositories
