#!/usr/bin/env bash

set -e

echo "===> [gamado-xS] Start provisioning Server Node..."

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install curl -y

echo "===> Intalling K3s"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --bind-address=192.168.56.110" sh -