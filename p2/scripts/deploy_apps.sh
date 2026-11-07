#!/bin/bash

while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
    echo "===> [arepsaS] K3s not ready, retrying in 3 seconds..."
    sleep 3
done
echo "===> [arepsaS] K3s kubeconfig is ready."

echo "===> [arepsaS] Deploying applications..."
kubectl apply -f /vagrant/apps/app1/app1-deployment.yaml
kubectl apply -f /vagrant/apps/app1/app1-service.yaml

kubectl apply -f /vagrant/apps/app2/app2-deployment.yaml
kubectl apply -f /vagrant/apps/app2/app2-service.yaml

kubectl apply -f /vagrant/apps/app3/app3-deployment.yaml
kubectl apply -f /vagrant/apps/app3/app3-service.yaml

kubectl apply -f /vagrant/ingress/ingress.yaml

echo "===> [arepsaS] Waiting for apps to be ready..."
if ! kubectl wait --for=condition=available deployment --all --timeout=300s; then
    echo "===> [arepsaS] Apps not ready after 300s. Check: kubectl get pods" >&2
    exit 1
fi

echo "===> [arepsaS] Waiting for Ingress to route traffic..."
for i in $(seq 1 60); do
    if curl -s -H "Host: app1.com" http://192.168.56.110 | grep -q "Hello from app1"; then
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo "===> [arepsaS] Ingress not routing after 180s. Check: kubectl get ingress" >&2
        exit 1
    fi
    sleep 3
done
echo "===> [arepsaS] Apps are reachable."
