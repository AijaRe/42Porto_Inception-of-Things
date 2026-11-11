
# Part 3 — K3d & Argo CD (GitOps)

This section walks you through a K3d cluster running inside Docker, with **Argo CD** in the `argocd` namespace deploying the app of the `dev` namespace from a public GitHub repository.

> **Work in progress:** the Argo CD `Application` (plan steps 6–7) is not written yet. See the [Project Plan](#project-plan).

## Index

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [The GitOps Repository](#the-gitops-repository)
- [Usage](#usage)
  - [1 — Install everything and create the cluster](#1--install-everything-and-create-the-cluster)
  - [2 — Verify the setup](#2--verify-the-setup)
  - [3 — Open the Argo CD interface](#3--open-the-argo-cd-interface)
  - [4 — Tear down](#4--tear-down)
- [Testing the Application](#testing-the-application)
- [Verification Commands](#verification-commands)
- [Troubleshooting](#troubleshooting)
- [Concepts Behind Part 3](#concepts-behind-part-3)
- [Project Plan](#project-plan)
- [Materials](#materials)
- [References](#references)

---

## Prerequisites

No Vagrant here: `scripts/setup.sh` installs everything directly on a **Debian 12** machine (or VM) with `sudo` and internet access. Ports `8080` and `8443` must be free.

| Tool | Purpose |
| :--- | :--- |
| [Docker](https://docs.docker.com/engine/install/debian/) | Runs the K3d nodes as containers |
| [K3d](https://k3d.io/) | Creates a K3s cluster inside Docker |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | Talks to the cluster |
| [Argo CD](https://argo-cd.readthedocs.io/) | Installed inside the cluster, watches the GitOps repo |

---

## Project Structure

```text
p3/
├── Makefile                 # setup / test / clean / fclean / re
└── scripts/
    ├── setup.sh             # Docker + K3d + kubectl, cluster, namespaces, Argo CD
    ├── verify_setup.sh      # Versions, node, namespaces, Argo CD access steps
    ├── clean.sh             # Deletes the K3d clusters and prunes Docker
    └── fclean.sh            # clean + removes k3d, kubectl and Docker
```

Cluster `argonauts` · namespaces `argocd` and `dev` · image `wil42/playground` (`v1`/`v2`, port `8888`).

---

## The GitOps Repository

The subject requires a **public** repository whose name contains a group member's login: [gabzaf/gamado-x-iot](https://github.com/gabzaf/gamado-x-iot). Its `manifests/` folder holds the `wil-playground` Deployment and Service for `dev`.

It was created from the terminal with the GitHub CLI:

```bash
gh repo create gamado-x-iot --public --clone && cd gamado-x-iot
git add manifests && git commit -m "add wil-playground v1 manifests"
git branch -M main && git push -u origin main
gh api repos/gabzaf/gamado-x-iot --jq '.visibility'   # public
```

More `gh` commands: [gabzaf/gh-cheatsheet](https://github.com/gabzaf/gh-cheatsheet).

---

## Usage

Run everything from the `p3` directory.

### 1 — Install everything and create the cluster

```bash
make setup
```

`setup.sh` skips what is already installed. It will:
1. Install **Docker**, **K3d** and **kubectl**, and add your user to the `docker` group.
2. Create the cluster **`argonauts`**, mapping host ports `8080 → 80` and `8443 → 443`.
3. Create the namespaces **`argocd`** and **`dev`**.
4. Install **Argo CD** in `argocd` and print the `admin` password.

### 2 — Verify the setup

```bash
make test
```

### 3 — Open the Argo CD interface

```bash
kubectl -n argocd port-forward svc/argocd-server 8081:443
```

Open [https://localhost:8081](https://localhost:8081) and log in as `admin`. Password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

### 4 — Tear down

```bash
make clean    # delete the K3d clusters and prune Docker
make fclean   # also uninstall k3d, kubectl and Docker
```

> `clean` runs `docker system prune -af`: it removes **every** unused Docker image on the machine, not only this project's.

---

## Testing the Application

Manual deploy of v1 (plan step 4):

```bash
kubectl apply -f https://raw.githubusercontent.com/gabzaf/gamado-x-iot/main/manifests/deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/gabzaf/gamado-x-iot/main/manifests/service.yaml
kubectl -n dev port-forward svc/wil-playground 8888:8888
curl http://localhost:8888/    # {"status":"ok", "message": "v1"}
```

Switch to v2 the GitOps way (plan step 7, needs the Argo CD `Application`):

```bash
# in the gamado-x-iot repository
sed -i 's/playground:v1/playground:v2/' manifests/deployment.yaml
git commit -am "deploy v2" && git push
# Argo CD replaces the pod; then curl answers "v2"
```

---

## Verification Commands

```bash
k3d cluster list                     # argonauts
kubectl get nodes                    # node Ready (a Docker container)
kubectl get ns argocd dev            # both namespaces exist
kubectl get pods -n argocd           # all Argo CD components Running
kubectl get applications -n argocd   # Synced / Healthy (once the Application exists)
kubectl get all -n dev               # wil-playground pod, Deployment and Service
```

---

## Troubleshooting

- **`permission denied ... docker.sock`** → the `docker` group is new for your session: log out and in, or run `newgrp docker`.
- **`kubectl` reaches the wrong cluster** → `setup.sh` keeps an existing `~/.kube/config`. Run `k3d kubeconfig merge argonauts --kubeconfig-switch-context`.
- **`port is already allocated`** → something already uses `8080` or `8443`.

---

## Concepts Behind Part 3

| Question | Where to read |
| :--- | :--- |
| What is K3d, and how is it different from K3s? | [K3d](../docs/k8s_concepts.md#1-k3d-containerized-k3s) / [Hierarchy](../docs/k8s_concepts.md#5-relationship--hierarchy-k8s-k3s-k3d-minikube) |
| What is GitOps? | [What is GitOps?](../docs/gitops_argocd.md#1-what-is-gitops) |
| CI vs CD: which one does Argo CD do? | [CI vs. CD](../docs/gitops_argocd.md#4-ci-vs-cd) |
| What is Argo CD? | [What is Argo CD?](../docs/gitops_argocd.md#5-what-is-argo-cd) |
| How does `kubectl` find the K3d cluster? | [Kubeconfig](../docs/k8s_concepts.md#kubeconfig-how-kubectl-finds-the-cluster) |
| How does v1 → v2 roll out? | [Deployment & Rollouts](../docs/k8s_concepts.md#65-deployment--rollout-management) |

---

## Project Plan

### 1. Environment Setup
- [x] 1.1. Create Docker installation script
- [x] 1.2. Create K3d installation script
- [x] 1.3. Create kubectl installation script

### 2. Kubernetes Cluster Setup
- [x] 2.1. Create a K3d cluster
- [x] 2.2. Verify cluster access with kubectl
- [x] 2.3. Create required namespaces (`argocd`, `dev`)

### 3. Git Repository Setup
- [x] 3.1. Create a public GitHub repository ([gabzaf/gamado-x-iot](https://github.com/gabzaf/gamado-x-iot))
- [x] 3.2. Add Kubernetes manifests to the repository

### 4. Application Deployment Test
- [x] 4.1. Configure Wil's Playground application (`wil42/playground:v1`)
- [ ] 4.2. Deploy version v1 manually for testing

### 5. Argo CD Setup
- [x] 5.1. Create a script to install Argo CD in the `argocd` namespace
- [x] 5.2. Verify Argo CD components are running
- [x] 5.3. Access the Argo CD interface

### 6. GitOps Configuration
- [ ] 6.1. Create an Argo CD `Application` resource
- [ ] 6.2. Connect Argo CD to the GitHub repository
- [ ] 6.3. Enable automatic synchronization

### 7. Continuous Deployment
- [ ] 7.1. Deploy application version v1 through Argo CD
- [ ] 7.2. Update configuration to version v2
- [ ] 7.3. Push changes to GitHub
- [ ] 7.4. Verify automatic deployment by Argo CD

---

## Materials

- [DEV - Why You Should Use k3d for Local Development](https://dev.to/cloudx/why-you-should-use-k3d-for-local-development-a-developers-guide-2cp5)
- [DevOps Lab - GitOps with Argo CD](https://albanna-tutorials.com/devops/advanced/a03_gitops.html)

## References

- **K3d**: [https://k3d.io/](https://k3d.io/)
- **Argo CD Getting Started**: [https://argo-cd.readthedocs.io/en/stable/getting_started/](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- **Argo CD Automated Sync**: [https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)
- **Docker image tags**: [https://docs.docker.com/reference/cli/docker/image/tag/](https://docs.docker.com/reference/cli/docker/image/tag/)
- **Wil's Playground image**: [https://hub.docker.com/r/wil42/playground](https://hub.docker.com/r/wil42/playground)
