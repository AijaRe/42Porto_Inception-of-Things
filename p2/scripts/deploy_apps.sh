#!/bin/bash

while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
    echo "===> [arepsaS] K3s not ready, retrying in 3 seconds..."
    sleep 3
done
echo "===> [arepsaS] K3s kubeconfig is ready."

echo "===> [arepsaS] Deploying applications..."
kubectl apply -f /vagrant/apps/app1/deployment-app1.yaml
kubectl apply -f /vagrant/apps/app1/service-app1.yaml

kubectl apply -f /vagrant/apps/app2/deployment-app2.yaml
kubectl apply -f /vagrant/apps/app2/service-app2.yaml

kubectl apply -f /vagrant/apps/app3/deployment-app3.yaml
kubectl apply -f /vagrant/apps/app3/service-app3.yaml