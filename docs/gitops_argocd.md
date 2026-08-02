# GitOps, CI/CD & Argo CD

A reference document explaining the core concepts of **GitOps**, **Continuous Integration (CI)**, **Continuous Deployment (CD)** and **Argo CD** as used in Part 3 (`p3`) of **Inception-of-Things**.

---

## 1. What is GitOps?

**GitOps** is an operational framework where **Git repositories serve as the single source of truth** for infrastructure and application configurations.

### Core Principles of GitOps:
1. **Declarative Descriptions**: The entire system state (K8s manifests, services, deployments) is defined declaratively in Git.
2. **Version Controlled & Auditable**: Every change (add, edit, delete) is made via Git commits, pull requests and history.
3. **Automated Pull-Based Sync**: Software agents inside the cluster automatically pull state changes from Git and apply them.
4. **Continuous Reconciliation (Self-Healing)**: Agents constantly compare the *desired state* in Git with the *actual state* in the cluster, automatically correcting any configuration drift.

---

## 2. What is Continuous Deployment (CD)?

**Continuous Deployment (CD)** is the practice of automatically deploying every approved code or manifest change directly into production or target environments without manual intervention.

In GitOps, CD means:
- Developers push updated K8s YAML manifests to GitHub.
- The GitOps controller detects the new commit.
- The cluster updates itself automatically within seconds.

---

## 3. What is Continuous Integration (CI)?

**Continuous Integration (CI)** is the practice of automatically building, testing and validating code whenever developers push changes to a shared repository.

In a modern software pipeline, CI handles:
- Running automated unit and integration tests.
- Linting and scanning code for security vulnerabilities.
- Building Docker container images and pushing them to a container registry (e.g., Docker Hub, GitHub Packages).

---

## 4. CI vs. CD

| Aspect | Continuous Integration (CI) | Continuous Deployment (CD) |
|---|---|---|
| **Primary Focus** | Code Quality, Testing & Building | Automated Release & Deployment |
| **Trigger** | Code push / Pull Request | Verified commit / Approved manifest update |
| **Output** | Tested code & built Docker images | Running applications inside the live K8s cluster |
| **Tools** | GitHub Actions, Jenkins, GitLab CI | Argo CD, Flux CD |

> **In GitOps & Inception-of-Things**:
> - **CI** tests code and builds Docker images.
> - **CD (Argo CD)** takes the updated K8s manifests and syncs them to the live cluster.

---

## 5. What is Argo CD?

**Argo CD** is a declarative, GitOps continuous delivery tool built specifically for **K8s**.

### Key Characteristics:
- **K8s-Native**: Runs as a set of controllers and custom resources inside the cluster (under the `argocd` namespace).
- **Automated Synchronization**: Periodically syncs Git repository state to Kubernetes resources.
- **Web UI & CLI**: Visual dashboard displaying live cluster status, pod logs, resource trees, and sync statuses.
- **Multitenancy & Health Checks**: Monitors health of deployments, pods, and services out of the box.

---

## 6. Summary Cheat Sheet

| Concept | Think of it as |
|---|---|
| **GitOps** | Git as the single source of truth for both code and cluster infrastructure |
| **CI** | Building and testing code before deployment |
| **CD** | Automatically deploying manifests to the live environment |
| **Argo CD** | The automated robot inside K8s that keeps the cluster matching Git |
