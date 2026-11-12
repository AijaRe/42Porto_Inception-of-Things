#!/bin/bash
set -e

echo "===> Docker & k3d verification"
docker --version
k3d version
k3d cluster list

echo "===> kubectl verification"
kubectl version --client
kubectl config current-context
kubectl get nodes

echo "===> namespace verification"
kubectl get namespace argocd
kubectl get namespace dev

echo "===> Argo CD Application (expect Synced / Healthy)"
kubectl get applications -n argocd
kubectl get all -n dev

echo "===> Argo CD UI test"
echo "1) Start port-forward: kubectl -n argocd port-forward svc/argocd-server 8081:443"
echo "2) Open URL: https://localhost:8081"
echo "3) Login: user=admin"
echo "4) Get password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d; echo"