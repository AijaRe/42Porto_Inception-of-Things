# GitOps, CD & Argo CD

A reference document explaining the core concepts of **GitOps**, **Continuous Deployment (CD)** and **Argo CD** as used in Part 3 (`p3`) of **Inception-of-Things**. Continuous Integration (CI) is not part of this project; it is covered as a next step at the end.

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

> **Which one does Argo CD do?** Only **CD**. It does not build or test code: it takes the manifests already in Git and syncs them to the cluster. Building and testing is the job of CI (see [Next Steps: Continuous Integration](#5-next-steps-continuous-integration-ci)).

---

## 3. What is Argo CD?

**Argo CD** is a declarative, GitOps continuous delivery tool built specifically for **K8s**.

### Key Characteristics:
- **K8s-Native**: Runs as a set of controllers and custom resources inside the cluster (under the `argocd` namespace).
- **Automated Synchronization**: Periodically syncs Git repository state to Kubernetes resources.
- **Web UI & CLI**: Visual dashboard displaying live cluster status, pod logs, resource trees, and sync statuses.
- **Health Checks**: Monitors health of deployments, pods, and services out of the box.

### Argo CD in p3

The flow in p3:

1. **Infrastructure**: `p3/scripts/setup.sh` creates the K3d cluster and the `argocd` and `dev` namespaces.
2. **Argo CD**: the same script installs Argo CD in the `argocd` namespace.
3. **Application**: it then applies [`p3/confs/application.yaml`](../p3/confs/application.yaml), which tells Argo CD to watch the `manifests` folder of the GitHub repository and deploy it to the `dev` namespace.
4. **Deploy a new version**: changing the image tag (e.g., `v1` → `v2`) in the repository and pushing to `main` is enough. Argo CD sees the cluster is `OutOfSync` and updates the Pods, with no manual `kubectl`.
5. **Self-heal**: with `selfHeal: true`, if someone deletes or edits a resource by hand, Argo CD restores what Git says. With `prune: true`, resources removed from Git are removed from the cluster too.

---

## 4. Summary Cheat Sheet

| Concept | Think of it as |
|---|---|
| **GitOps** | Git as the single source of truth for both code and cluster infrastructure |
| **CD** | Automatically deploying manifests to the live environment |
| **Argo CD** | The automated robot inside K8s that keeps the cluster matching Git |
| **Application** | Argo CD resource saying which repo/path to sync to which namespace |

---

## 5. Next Steps: Continuous Integration (CI)

p3 stops at CD: the image (`v1` / `v2`) is already built and published, and only the manifest changes. In a real pipeline, a **CI** stage comes before it.

### What is CI?

**Continuous Integration (CI)** is the practice of automatically building, testing and validating code whenever developers push changes to a shared repository.

CI usually handles:
- Running automated unit and integration tests.
- Linting and scanning code for security vulnerabilities.
- Building Docker container images and pushing them to a container registry (e.g., Docker Hub, GitHub Packages).

### CI vs. CD

| Aspect | Continuous Integration (CI) | Continuous Deployment (CD) |
|---|---|---|
| **Primary Focus** | Code Quality, Testing & Building | Automated Release & Deployment |
| **Trigger** | Code push / Pull Request | Verified commit / Approved manifest update |
| **Output** | Tested code & built Docker images | Running applications inside the live K8s cluster |
| **Tools** | GitHub Actions, Jenkins, GitLab CI | Argo CD, Flux CD |

### The Full Pipeline

```text
Developer pushes code
      │
      ▼
CI (e.g., GitHub Actions) ── tests, builds image myapp:v2, pushes it to Docker Hub
      │
      ▼
Manifest updated in Git ── image tag v1 → v2 (by hand or by the CI itself)
      │
      ▼
CD (Argo CD) ── detects OutOfSync, updates the Pods in the cluster
```

A natural next step after this project is to add a CI workflow (e.g., GitHub Actions) that builds the image and updates the tag in the manifests repository, so a code push ends up in the cluster with no manual step.
