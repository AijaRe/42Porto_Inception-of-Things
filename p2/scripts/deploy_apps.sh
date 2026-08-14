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