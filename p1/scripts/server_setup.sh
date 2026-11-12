#!/usr/bin/env bash

set -e

echo "===> [gamado-xS] Start provisioning Server Node..."

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install curl -y

# 1 GB of swap on disk: RAM stays at 1 GB as the subject advises, but K3s no
# longer freezes the VM for minutes when memory runs out.
if [ ! -f /swapfile ]; then
    echo "===> [gamado-xS] Creating 1 GB swap file..."
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi
swapon --show | grep -q /swapfile || sudo swapon /swapfile

echo "===> [gamado-xS] Installing K3s"

if [ -f /usr/local/bin/k3s ]; then
    echo "===> [gamado-xS] k3s is already installed. Skipping installation."
else
    # Download first: with "curl | sh", a failed download runs an empty script
    # that exits 0, and K3s would silently not be installed.
    echo "===> [gamado-xS] Downloading the K3s installer..."
    curl -sfL --retry 5 --retry-delay 3 https://get.k3s.io -o /tmp/k3s-install.sh
    K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="server \
  		--node-ip=192.168.56.110 \
  		--bind-address=192.168.56.110 \
		--disable=traefik \
		--disable=servicelb \
		--disable=metrics-server" sh /tmp/k3s-install.sh
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
