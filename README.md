# Inception-of-Things (IoT)

A System Administration project from the 42 curriculum that practices DevOps tooling: infrastructure as code with **Vagrant**, cluster orchestration with **K3s** and **K3d**, Ingress routing with **Traefik** and **GitOps** continuous deployment with **Argo CD**.

To achieve this efficiently, the project utilizes **K3s**:
- **Standard K8s** is powerful, but large and resource-intensive (often requiring several GBs of RAM and complex setups).
- **K3s** is a lightweight, fully compliant K8s distribution designed for low resource consumption and easy installation.

> **Analogy**: Think of standard K8s as a full Ubuntu Desktop installation and **K3s** as Alpine Linux, with the same core capabilities, but significantly lighter.

---

## Project Architecture Overview

The project is structured into three parts, each demonstrating progressive concepts of K8s orchestration and GitOps automation:

| Part | Name | Stack | Summary |
| :--- | :--- | :--- | :--- |
| **`p1`** | **K3s & Vagrant** | K3s, Vagrant | Configures a multi-node K3s cluster across two VMs (1 Server and 1 Worker Agent) with automated passwordless SSH and static IPs (`192.168.56.110` / `111`). |
| **`p2`** | **K3s & Multi-App Routing** | K3s, Ingress, Vagrant | Deploys 3 web apps on a single K3s node (`192.168.56.110`). Routes traffic via **Ingress** based on HTTP Host headers (`app1.com`, `app2.com` with 3 replicas and default fallback `app3`). |
| **`p3`** | **K3d & Argo CD (GitOps)** | K3d, Docker, Argo CD, GitHub | Sets up a K3d cluster running in Docker. Uses **Argo CD** in a dedicated namespace (`argocd`) to continuously deploy and update an application in the `dev` namespace from a remote Git repository. |

---

## Getting Started

Each part has its own README with prerequisites, setup steps, teardown instructions and verification commands to confirm the VMs meet the subject specs:

- **Part 1** — [K3s & Vagrant](./p1/README.md)
- **Part 2** — [K3s & Multi-App Routing](./p2/README.md)
- **Part 3** — [K3d & Argo CD (GitOps)](./p3/README.md)

---

## Key Learning Objectives

The project automates VM provisioning with **Vagrant**, runs lightweight Kubernetes with **K3s** on VMs and **K3d** in Docker, exposes several apps behind one IP through an **Ingress** that routes by HTTP `Host`, and ends with **GitOps** continuous deployment: **Argo CD** keeps the cluster matching a Git repository. It covers CD only; CI (building and testing images) is left as a [next step](./docs/gitops_argocd.md#5-next-steps-continuous-integration-ci).

---

## Documentation & Concepts Guide

For detailed explanations of core DevOps and K8s concepts, check out:
- [Vagrant](./docs/vagrant.md)
- [Kubernetes Concepts](./docs/k8s_concepts.md)
- [GitOps, CD & Argo CD Concepts](./docs/gitops_argocd.md)
