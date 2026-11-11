
# Part 3 - K3d and Argo CD 

## Project Plan

### 1. Environment Setup
1.1. Create Docker installation script  
1.2. Create K3d installation script  
1.3. Create kubectl installation script

### 2. Kubernetes Cluster Setup
2.1. Create a K3d cluster  
2.2. Verify cluster access with kubectl  
2.3. Create required namespaces

### 3. Git Repository Setup
3.1. Create a public GitHub repository ([gabzaf/gamado-x-iot](https://github.com/gabzaf/gamado-x-iot))  
3.2. Add Kubernetes manifests to the repository

The repository was created and filled from the terminal with the GitHub CLI (`gh`):

```bash
gh repo create gamado-x-iot --public --clone && cd gamado-x-iot
mkdir -p manifests            # deployment.yaml + service.yaml (wil42/playground:v1, namespace dev)
git add manifests && git commit -m "add wil-playground v1 manifests"
git branch -M main && git push -u origin main
```

Check that it is public and holds the manifests:

```bash
gh api repos/gabzaf/gamado-x-iot --jq '.visibility, .default_branch'
gh api repos/gabzaf/gamado-x-iot/contents/manifests --jq '.[].name'
```

More `gh` commands (collaborators, PRs, `gh api`, GitOps path): [gabzaf/gh-cheatsheet](https://github.com/gabzaf/gh-cheatsheet).

### 4. Application Deployment Test
4.1. Configure Wil's Playground application  
4.2. Deploy version v1 manually for testing  

### 5. Argo CD Setup
5.1. Create a script to install Argo CD in the argocd namespace  
5.2. Verify Argo CD components are running  
5.3. Access the Argo CD interface

### 6. GitOps Configuration
6.1. Create an Argo CD Application resource  
6.2. Connect Argo CD to the GitHub repository  
6.3. Enable automatic synchronization

### 7. Continuous Deployment
7.1. Deploy application version v1 through Argo CD  
7.2. Update configuration to version v2  
7.3. Push changes to GitHub  
7.4. Verify automatic deployment by Argo CD



### Materials
[DEV. Why You Should Use k3d for Local Development.](https://dev.to/cloudx/why-you-should-use-k3d-for-local-development-a-developers-guide-2cp5)

[DevOps Lab. GitOps with Argo CD.](https://albanna-tutorials.com/devops/advanced/a03_gitops.html?utm_source=copilot.com)

[Official docs. Docker image tags.](https://docs.docker.com/reference/cli/docker/image/tag/)