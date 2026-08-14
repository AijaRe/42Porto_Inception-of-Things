# Part 2 - K3s Single‑Node Cluster with Three Applications 

## Project Structure

.
├── Vagrantfile
├── scripts/
│   ├── server_setup.sh      # Installs K3s and prepares kubectl
│   └── deploy_apps.sh       # Applies all Kubernetes YAML files
└── apps/
├── app1/
│   ├── deployment-app1.yaml
│   └── service-app1.yaml
├── app2/
│   ├── deployment-app2.yaml
│   └── service-app2.yaml
└── app3/
├── deployment-app3.yaml
└── service-app3.yaml
├── ingress/
    └── ingress.yaml


## How to Run

### 1. Start the VM and provision everything

```bash
vagrant up
```

This will:

- Create the VM  
- Install K3s (first run only)  
- Deploy all three applications  

### 2. Re‑provision only the app deployment step

If you modify YAML files:

```bash
vagrant provision --provision-with DeployApps
```


### 3. Access the VM

```bash
vagrant ssh
```


### 4. Check Kubernetes status inside the VM

```bash
kubectl get all
kubectl get nodes -o wide
kubectl get pods -A
kubectl get svc -A
```

### Materials
[IBM What is Ingress](https://www.youtube.com/watch?v=NPFbYpb0I7w)
