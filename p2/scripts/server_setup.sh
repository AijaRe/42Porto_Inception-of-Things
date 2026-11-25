#!/usr/bin/env bash

set -e

echo "===> [arepsaS] Start provisioning Server Node..."

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install curl -y

echo "===> [arepsaS] Installing K3s"

if [ -f /usr/local/bin/k3s ]; then
    echo "===> [arepsaS] k3s is already installed. Skipping installation."
else
    # Download first: with "curl | sh", a failed download runs an empty script
    # that exits 0, and K3s would silently not be installed.
    echo "===> [arepsaS] Downloading the K3s installer..."
    curl -sfL --retry 5 --retry-delay 3 https://get.k3s.io -o /tmp/k3s-install.sh
    PRIVATE_IFACE=$(ip -4 -o addr show | awk '$4 == "192.168.56.110/24" {print $2; exit}')
    test -n "$PRIVATE_IFACE" || { echo "Private network interface not found" >&2; exit 1; }
    K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="server \
  		--node-ip=192.168.56.110 \
  		--bind-address=192.168.56.110 \
		--flannel-iface=$PRIVATE_IFACE \
		--disable=metrics-server" sh /tmp/k3s-install.sh
    echo "===> [arepsaS] k3s server installed successfully."
fi

# Add kubectl alias for vagrant user
echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
echo 'alias k="kubectl"' >> /home/vagrant/.bashrc
echo 'complete -F __start_kubectl k' >> /home/vagrant/.bashrc

echo "===> [arepsaS] k3s server setup complete."
