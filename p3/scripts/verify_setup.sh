#!/bin/bash
echo "===> Docker & k3d Verification"

docker --version
k3d version
k3d cluster list
kubectl version --client