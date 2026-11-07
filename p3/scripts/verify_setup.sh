#!/bin/bash
set -e

echo "===> Docker & k3d Verification"

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