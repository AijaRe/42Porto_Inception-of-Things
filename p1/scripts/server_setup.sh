#!/usr/bin/env bash

set -e

echo "===> [gamado-xS] Start provisioning Server Node..."

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install curl -y

echo "===> [gamado-xS] Installing K3s"

if [ -f /usr/local/bin/k3s ]; then
    echo "===> [gamado-xS] k3s is already installed. Skipping installation."
else
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --bind-address=192.168.56.110" sh -
    sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    echo "===> [gamado-xS] k3s server installed successfully."
fi

if [ -d /vagrant ]; then
    echo "===> [gamado-xS] Copying token for joining worker nodes..."
    sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token
else
    echo "===> [gamado-xS] /vagrant is not mounted. Skipping token copy."
fi

echo "===> [gamado-xS] k3s server setup complete."