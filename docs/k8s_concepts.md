# Kubernetes

A reference document explaining the core concepts of **K8s**, **K3s**, **K3d**, **Minikube** and Kubernetes primitives.

> **Context**: This reference guide forms part of the DevOps project, documenting containerization, cluster orchestration with Vagrant, K3s, K3d, Ingress controllers and GitOps continuous deployment with Argo CD.

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

### Container Runtimes & CRI Tools
Kubernetes does not interact with Docker directly anymore; it uses the **Container Runtime Interface (CRI)**:
- **`crictl`**: CLI tool designed to inspect and debug CRI-compatible container runtimes directly on cluster nodes.
- **`nerdctl`**: A Docker-compatible CLI for `containerd`.

---

## 2. Why is it called K8s?

K8s is a numeronym. The name **"Kubernetes"** starts with a **K**, ends with an **s** and has **8 letters in between**.

---

## 3. What is K3s?

Standard K8s is extremely powerful, but it is large, complex and resource-heavy (often consuming several gigabytes of RAM just for control plane components).

**K3s** is a lightweight, fully compliant Kubernetes distribution.

### Key Characteristics:
- **100% K8s-compatible**: Uses the exact same `kubectl` commands and YAML manifests.
- **Lightweight footprint**: Packaged as a single binary under 100 MB with low memory usage.
- **Simplified Setup**: Strips out legacy cloud-provider drivers and external dependencies.
- **Use Cases**: Ideal for learning, local development, labs, edge devices (e.g., Raspberry Pi) and Vagrant virtual machines.

---

## 4. What is K3d & Minikube?

Different tools exist to run local Kubernetes clusters for development:

### 1. K3d (Containerized K3s)
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

### 2. Minikube
**Minikube** is a single-node local Kubernetes cluster tool. It can run inside a Virtual Machine hypervisor (e.g., VirtualBox, KVM) or via Docker/Podman drivers.
```bash
minikube start
minikube service my-service --url
```

> **When to pick which?**: Choose **K3d** for rapid multi-node cluster simulation inside Docker containers (ideal for local multi-node testing and fast CI/CD pipelines). Choose **Minikube** for single-node local development when you need a rich set of built-in addons (e.g., Ingress, Dashboard, Metrics Server) and a closer-to-production VM feature set.

---

## 5. Relationship & Hierarchy (K8s, K3s, K3d, Minikube)

```text
                      Kubernetes (K8s)
                       │           │
           Lightweight │           │ Local Single-Node
          Distribution │           │ Test Environment
                       ▼           ▼
                      K3s       Minikube
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

*Analogy: Each node is an office building in the company.*

---

### 6.3 Pod
The smallest deployable unit in K8s. A Pod wraps one (or occasionally more helper/sidecar) containers. K8s manages Pods rather than containers directly.

- **Shared Network**: Containers in the same Pod share the same network namespace and can communicate via `localhost`.
- **Shared Storage**: Containers in the same Pod can mount and share identical volume storage.
- **Imperative Creation**:
  - `kubectl run nginx --image=nginx` (Creates a **Pod** directly — since v1.18+).
  - `kubectl create deployment nginx --image=nginx` (Creates a **Deployment**).

---

### 6.4 Controller Evolution: ReplicationController vs ReplicaSet

To keep multiple Pod instances running simultaneously, K8s relies on replication controllers:

- **ReplicationController (Legacy)**: Older controller enforcing pod replica counts.
- **ReplicaSet (Modern)**: The modern replication engine. Unlike ReplicationControllers, ReplicaSets use powerful **Label Selectors** (`spec.selector.matchLabels`). This allows ReplicaSets to acquire and manage Pods created independently or prior to the ReplicaSet creation.

```text
Deployment ──> ReplicaSet ──> Pod 1, Pod 2, Pod 3
```

#### 3 Ways to Scale Pod Replicas:
1. **Declarative**: Update `replicas: N` in definition file $\rightarrow$ `kubectl apply -f manifest.yml`
2. **Imperative**: `kubectl scale --replicas=6 -f manifest.yml` or `kubectl scale replicaset myapp-replicaset --replicas=6`
3. **Autoscaling**: Automatically scale based on CPU/RAM load using Horizontal Pod Autoscaler (HPA).

---

### 6.5 Deployment & Rollout Management

Ensures that the desired number of Pods are running and healthy at all times, while managing application updates, revisions and rollbacks.

*Analogy: A safety & operations manager ensuring active instances match desired state and managing safe upgrades.*

#### Rollouts & Rollbacks:
When updating a container image or configuration, Deployments execute a **Rolling Update** by default (gradually replacing old Pods with new ones without service downtime).

| Command | Purpose |
|---|---|
| `kubectl rollout status deployment/myapp` | Monitor live rollout progress |
| `kubectl rollout history deployment/myapp` | View revision history |
| `kubectl rollout undo deployment/myapp` | Roll back to the previous stable revision |

---

### 6.6 Networking & Service Types Deep-Dive

#### Pod Networking & CNI
Every Pod in K8s receives its own unique IP address. Kubernetes delegates internal cluster networking to **Container Network Interface (CNI)** plugins (e.g., Flannel, Calico, Cilium, Weave Net).

#### Services
A **Service** provides a stable IP address, DNS entry, and load balancing for Pods whose individual IP addresses change dynamically whenever they restart or scale.

```text
External/Internal Request ──> Service ──> Pod 1, Pod 2, Pod 3
```

#### The 3 Core Service Types:

1. **`ClusterIP` (Default)**:
   - Assigns a virtual IP address **internal to the cluster**.
   - Enables communication between internal application tiers (e.g., Frontend $\rightarrow$ Backend $\rightarrow$ Database).
2. **`NodePort`**:
   - Exposes the service externally on each Node's IP at a static port (Port Range: **`30000-32767`**).
   - Maps `NodePort` $\rightarrow$ `Service Port` $\rightarrow$ `Target Container Port`.
   - Load balances requests randomly across matching Pods across nodes.
3. **`LoadBalancer`**:
   - Integrates with external cloud provider load balancers (AWS ELB, GCP LB, Azure LB) or bare-metal load balancers (MetalLB) to direct external internet traffic into the cluster.

---

### 6.7 Ingress
Manages external HTTP/HTTPS traffic entering the cluster, routing browser or client requests to the correct internal Service based on hostname or URL path.

```text
Browser ──> Ingress ──> Service ──> Pod ──> Container
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

---

### Complete End-to-End Manifest Example (Deployment + Service + Ingress)

The following YAML demonstrates how a **Deployment**, **Service** and **Ingress** connect together via **Labels and Selectors**:

```yaml
# 1. Deployment (Application Workload)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-web-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-web-app
  template:
    metadata:
      labels:
        app: my-web-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
---
# 2. Service (Internal Load Balancer & Stable Endpoint)
apiVersion: v1
kind: Service
metadata:
  name: my-web-service
  namespace: default
spec:
  type: ClusterIP
  selector:
    app: my-web-app        # Matches the Pod labels defined in Deployment above
  ports:
  - port: 80              # Internal cluster service port
    targetPort: 80        # Container port listening inside Pod
---
# 3. Ingress (External HTTP Routing)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-web-ingress
  namespace: default
spec:
  rules:
  - host: app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-web-service  # Directs traffic to the Service above
            port:
              number: 80
```

> **How they link together**:
> 1. **Ingress $\rightarrow$ Service**: `backend.service.name: my-web-service` matches `Service.metadata.name: my-web-service`.
> 2. **Service $\rightarrow$ Pods**: `Service.spec.selector.app: my-web-app` matches `Deployment.spec.template.metadata.labels.app: my-web-app`.

---

## 8. How Everything Works Together

### Request Flow
```text
Internet
   │
   ▼
Ingress (Host & Path Routing: app.local /)
   │
   ▼
Service (Stable Endpoint: my-web-service:80)
   │
   ▼
Deployment (Lifecycle & Replica Manager)
   │
   ▼
ReplicaSet (Pod Count & Label Matcher: app=my-web-app)
   │
   ▼
Pod (Container Wrapper & Shared Network/Storage)
   │
   ▼
Container (Nginx Container on port 80)
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

### Declarative Operations
```bash
kubectl apply -f manifest.yaml   # Create or update resources
kubectl delete -f manifest.yaml  # Delete resources defined in manifest
```

### Imperative Resource Creation
```bash
kubectl run nginx --image=nginx                # Create a Pod directly
kubectl create deployment nginx --image=nginx # Create a Deployment
```

### Inspection & Debugging
```bash
kubectl get nodes                        # List cluster nodes
kubectl get pods -o wide                 # List Pods with IP and assigned Node
kubectl get services                     # List active Services
kubectl get deployments                  # List active Deployments
kubectl get all                          # List all active resources in namespace
kubectl describe pod nginx               # View detailed lifecycle events & status
kubectl edit deployment myapp-deployment # Edit live manifest directly in cluster
```

### Rollout & History Management
```bash
kubectl rollout status deployment/myapp-deployment  # Monitor update rollout status
kubectl rollout history deployment/myapp-deployment # View deployment revisions
kubectl rollout undo deployment/myapp-deployment    # Rollback to previous deployment
```

---

## 10. Summary Cheat Sheet

| Concept | Think of it as |
|---|---|
| **Cluster** | The entire K8s environment |
| **Node** | A machine (VM or physical server) in the cluster |
| **Pod** | A wrapper around one or more containers (sharing network & storage) |
| **ReplicaSet** | Ensures exact count of Pod replicas via label selectors |
| **Deployment** | Manages ReplicaSets, rolling updates, history, and rollbacks |
| **Service** | Stable entry point for Pods (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| **Ingress** | Routes external HTTP/HTTPS traffic into internal Services |
| **CNI** | Cluster networking plugin (Flannel, Calico, Cilium) assigning Pod IPs |
| **Manifest** | YAML blueprint defining desired cluster state |
| **k3s / Minikube** | Lightweight/local K8s environments for development & testing |

---

## 11. Concepts Progression in Inception-of-Things

The 42 School **Inception-of-Things (IoT)** project builds up DevOps expertise sequentially:

1. **Containers & Virtualization**: Docker & Vagrant VM provisioning
2. **Cluster Topology**: Master/Server Node vs. Worker Node setup
3. **Core K8s Primitives**: Pods, ReplicaSets, Services, and Deployments
4. **Traffic Management**: Ingress Controllers and Host-based HTTP routing
5. **GitOps & Continuous Deployment**: Declarative sync with Argo CD & Git repositories

---

## 12. References & Resources

- **Kubernetes Documentation - Concepts**: [https://kubernetes.io/docs/concepts/](https://kubernetes.io/docs/concepts/)
- **Pod Overview**: [https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/)
- **Kubernetes Tools Installation**: [https://kubernetes.io/docs/tasks/tools/](https://kubernetes.io/docs/tasks/tools/)
- **K3s Documentation**: [https://docs.k3s.io/](https://docs.k3s.io/)
- **K3d Documentation**: [https://k3d.io/](https://k3d.io/)
- **Minikube Documentation**: [https://minikube.sigs.k8s.io/docs/](https://minikube.sigs.k8s.io/docs/)
- **Kubernetes Container Runtimes (CRI)**: [https://kubernetes.io/docs/setup/production-environment/container-runtimes/](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
- **`crictl` Debugging Tool**: [https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/](https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/)
- **`nerdctl` CLI Project**: [https://github.com/containerd/nerdctl](https://github.com/containerd/nerdctl)

