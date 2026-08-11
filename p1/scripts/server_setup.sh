#!/usr/bin/env bash

set -e

echo "===> [gamado-xS] Start provisioning Server Node..."

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install curl -y

echo "===> [gamado-xS] Installing K3s"

if [ -f /usr/local/bin/k3s ]; then
    echo "===> [gamado-xS] k3s is already installed. Skipping installation."
else
    curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="server \
  		--node-ip=192.168.56.110 \
  		--bind-address=192.168.56.110 \
		--disable=traefik \
		--disable=servicelb \
		--disable=metrics-server" sh -
    echo "===> [gamado-xS] k3s server installed successfully."
fi

if [ -d /vagrant ]; then
    echo "===> [gamado-xS] Copying token for joining worker nodes..."
    sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/k3s-token
else
    echo "===> [gamado-xS] /vagrant is not mounted. Skipping token copy."
fi

# Add kubectl alias for vagrant user
echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
echo 'alias k="kubectl"' >> /home/vagrant/.bashrc
echo 'complete -F __start_kubectl k' >> /home/vagrant/.bashrc

echo "===> [gamado-xS] k3s server setup complete."
