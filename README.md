# Inception-of-Things (IoT)

A SysAdmin & DevOps project focused on introducing **K8s**, **Vagrant** and **GitOps CI/CD** using **Argo CD**.

To achieve this efficiently, the project utilizes **K3s**:
- **Standard K8s** is powerful, but large and resource-intensive (often requiring several GBs of RAM and complex setups).
- **K3s** is a lightweight, fully compliant K8s distribution designed for low resource consumption and easy installation.

> **Analogy**: Think of standard K8s as a full Ubuntu Desktop installation and **K3s** as Alpine Linux, with the same core capabilities, but significantly lighter.

---

## Project Architecture Overview

The project is structured into three parts, each demonstrating progressive concepts of K8s orchestration and GitOps automation:

| Part | Name | Stack | Summary |
| :--- | :--- | :--- | :--- |
| **`p1`** | **K3s & Vagrant** | K3s, Vagrant | Configures a multi-node K3s cluster inside two VMs (1 Server and 1 Worker Agent) with automated passwordless SSH and static IPs (`192.168.56.110` / `111`). |
| **`p2`** | **K3s & Multi-App Routing** | K3s, Ingress, Vagrant | Deploys 3 web apps on a single K3s node (`192.168.56.110`). Routes traffic via **Ingress** based on HTTP Host headers (`app1.com`, `app2.com` with 3 replicas and default fallback `app3`). |
| **`p3`** | **K3d & Argo CD (GitOps)** | K3d, Docker, Argo CD, GitHub | Sets up a K3d cluster running in Docker. Uses **Argo CD** in a dedicated namespace (`argocd`) to continuously deploy and update an application in the `dev` namespace from a remote Git repository. |

---

## Getting Started — Part 1 (`p1`)

This section walks you through spinning up the two-node K3s cluster defined in `p1`.

### Prerequisites

Make sure the following tools are installed on your host machine before proceeding:

| Tool | Purpose |
| :--- | :--- |
| [VirtualBox](https://www.virtualbox.org/) | Hypervisor that runs the VMs |
| [Vagrant](https://www.vagrantup.com/) | Automates VM provisioning |

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

### 4 — SSH into a VM (optional)

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

## Key Learning Objectives

- **Virtualization & Automation**: Automating VM provisioning and system configuration using Vagrant.
- **Lightweight K8s**: Deploying and managing **K3s** and **K3d** (K3s in Docker containers).
- **Cluster Networking & Ingress**: Exposing services and configuring Host-based HTTP routing using K8s Ingress controllers.
- **GitOps & CI/CD**: Achieving declarative infrastructure management and automated synchronization via **Argo CD**.

---

## Documentation & Concepts Guide

For detailed explanations of core DevOps and K8s concepts, check out:
- [Kubernetes Concepts](./docs/k8s_concepts.md)
- [GitOps, CI/CD & Argo CD Concepts](./docs/gitops_argocd.md)
