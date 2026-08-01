# Kubernetes

A reference document explaining the core concepts of **K8s**, **K3s** and **K3d**

---

## 1. What is Kubernetes (K8s)?

**Kubernetes** or **K8s** is a platform for orchestrating, automating and managing containerized applications at scale.

When running hundreds of containers across multiple machines, Kubernetes automatically handles:
- **Auto-healing**: Starts crashed containers and stops unresponsive ones.
- **Scaling**: Scales applications up or down based on load.
- **Load Balancing**: Distributes network traffic evenly across containers.
- **Zero-downtime Deployments**: Rolling updates and rollbacks without stopping service.
- **Storage & Networking**: Manages persistent volumes and internal cluster DNS.

### What about Docker Compose?

- **Docker Compose** is designed to manage multi-container applications on a **single machine** (`docker compose up`).
- **Kubernetes** is designed to manage multi-container applications across a **cluster of multiple machines** with auto-healing, load balancing, zero-downtime updates and automated scaling.

> **Rule of thumb**: Use **Docker Compose** for quick local development on 1 machine. Use **Kubernetes** for managing production workloads across clusters.

---

## 2. Why is it called K8s?

**K8s** is a numeronym. The name **"Kubernetes"** starts with a **K**, ends with an **s** and has **8 letters in between**.
---

## 3. What is K3s?

Standard Kubernetes is extremely powerful, but it is large, complex and resource-heavy (often consuming several gigabytes of RAM just for control plane components).

**K3s** is a lightweight, fully compliant Kubernetes distribution.

### Key Characteristics:
- **100% Kubernetes-compatible**: Uses the exact same `kubectl` commands and YAML manifests.
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

## 5. Relationship & Hierarchy

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

## 6. Why use K3s & K3d?

A full production K8s cluster is too resource-demanding for typical student hardware. 

By using **K3s** and **K3d**:
- **K3s** teaches real-world K8s orchestration and configuration concepts.
- **K3d** enables rapid cluster creation, testing and teardown using local containers.

### Core Concepts Transferred Directly to Production K8s:
- **Pods** & **Nodes**
- **Deployments** & **ReplicaSets**
- **Services** (ClusterIP, NodePort, LoadBalancer)
- **Ingress Controllers** & Routing Rules
- **Namespaces** & Resource Isolation
- **Persistent Volumes** & ConfigMaps
- **YAML Manifests** & `kubectl` CLI commands

---

## 7. Concepts Progression in Inception-of-Things

The project builds up DevOps expertise sequentially:

1. **Containers & Virtualization**: Docker & Vagrant VM provisioning
2. **Cluster Topology**: Master/Server Node vs. Worker Node setup
3. **Core Kubernetes Primitives**: Pods, Services and Deployments
4. **Traffic Management**: Ingress Controllers and Host-based HTTP routing
5. **GitOps & Continuous Deployment**: Declarative sync with Argo CD & Git repositories

