# GitOps, CD & Argo CD

A reference document explaining **GitOps**, **Continuous Deployment (CD)** and **Argo CD** as used in Part 3 (`p3`) of **Inception-of-Things**.

---

## 1. What is GitOps?

In **GitOps**, a Git repository is the **single source of truth** for what runs in the cluster. The desired state is written declaratively (K8s manifests), every change is a commit, and an agent inside the cluster pulls those changes and applies them. The agent also keeps comparing Git with the cluster and undoes any drift, so a manual change does not survive.

---

## 2. What is Continuous Deployment (CD)?

**Continuous Deployment** means every approved change reaches the running environment automatically, with no manual step. In GitOps, that change is a commit to the manifests: the controller notices it and updates the cluster within seconds.

Argo CD does only CD. It does not build or test code; it takes the manifests already in Git and syncs them to the cluster. Building and testing belongs to CI (see [Next Steps](#5-next-steps-continuous-integration-ci)).

---

## 3. What is Argo CD?

**Argo CD** is a GitOps CD tool built for K8s. It runs as controllers in its own namespace (`argocd`), polls the Git repository, compares it with the cluster and applies the differences. Its web UI shows each application's resources, their health and whether they are `Synced` or `OutOfSync`.

What Argo CD watches is described by an **Application**, a custom resource (`argoproj.io/v1alpha1`) that says which repository, branch and path to read and to which cluster and namespace to deploy.

### Argo CD in p3

`p3/scripts/setup.sh` creates the K3d cluster, the `argocd` and `dev` namespaces, installs Argo CD and applies [`p3/confs/application.yaml`](../p3/confs/application.yaml). That Application points Argo CD to the `manifests` folder of the GitHub repository, branch `main`, and deploys it to `dev`.

From then on, deploying a new version is a commit: changing the image tag from `v1` to `v2` and pushing is enough for Argo CD to mark the app `OutOfSync` and roll out the new Pods, with no `kubectl`. Its `syncPolicy.automated` has two options: `selfHeal: true` restores anything edited or deleted by hand in the cluster, and `prune: true` deletes from the cluster what was deleted from Git.

---

## 4. Cheat Sheet

| Concept | Think of it as |
|---|---|
| **GitOps** | Git as the single source of truth for the cluster |
| **CD** | Every approved change deployed automatically |
| **Argo CD** | The agent in the cluster that keeps it matching Git |
| **Application** | Which repo/path Argo CD syncs to which namespace |
| **selfHeal / prune** | Undo manual changes / delete what left Git |

---

## 5. Next Steps: Continuous Integration (CI)

p3 starts from an image that is already built (`wil42/playground:v1` and `v2`). In a real pipeline, a **CI** stage produces it: on every push it runs the tests, scans the code, builds the image and pushes it to a registry such as Docker Hub.

### CI vs. CD

CI checks and packages the code; CD delivers the result to the cluster. CI is triggered by a code push or pull request and ends with a tested image; CD is triggered by a manifest change and ends with Pods running that image. Typical CI tools are GitHub Actions, Jenkins and GitLab CI; typical GitOps CD tools are Argo CD and Flux CD.

```text
Code push ─► CI: test, build myapp:v2, push to registry
          ─► manifest tag v1 → v2 (by hand or by CI)
          ─► CD (Argo CD): OutOfSync → rolls out v2
```

A natural next step after this project is a CI workflow (e.g., GitHub Actions) that builds the image and updates the tag in the manifests repository, so a code push reaches the cluster with no manual step.

---

## 6. References

- **Argo CD Documentation**: [https://argo-cd.readthedocs.io/](https://argo-cd.readthedocs.io/)
- **Argo CD Automated Sync (prune, selfHeal)**: [https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)
- **Argo CD Application spec**: [https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
- **OpenGitOps Principles**: [https://opengitops.dev/](https://opengitops.dev/)
