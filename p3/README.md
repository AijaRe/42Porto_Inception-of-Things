
# Part 3 - K3d and Argo CD 

## Project Plan

### 1. Environment Setup
1.1. Create Docker installation script  
1.2. Create K3d installation script  
1.3. Create a master setup script  

### 2. Kubernetes Cluster Setup
2.1. Create a K3d cluster  
2.2. Verify cluster access with kubectl  
2.3. Create required namespaces

### 3. Git Repository Setup
3.1. Create a public GitHub repository  
3.3. Add Kubernetes manifests to the repository

### 4. Application Deployment Test
4.1. Configure Wil's Playground application  
4.2. Deploy version v1 manually for testing  

### 5. Argo CD Setup
5.1. Install Argo CD in the argocd namespace  
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