#!/bin/bash
echo "===== Docker & k3d Verification ====="

docker --version
k3d version
sudo k3d cluster list

# kubectl get nodes