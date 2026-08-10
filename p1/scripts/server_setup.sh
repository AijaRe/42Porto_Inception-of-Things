#!/bin/bash
set -e

# Install k3s server mode
echo "[INFO-42]  Installing k3s server mode..."

if [ -f /usr/local/bin/k3s ]; then
    echo "[INFO] k3s is already installed. Skipping installation."
else
    echo "[INFO-42] Installing k3s server mode..."
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s -
	echo "[INFO-42] adding permissions to kubeconfig..."
	sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    echo "[INFO-42] k3s server installed successfully."
fi

if [ -d /vagrant ]; then
    echo "[INFO-42] Copying token for joining worker nodes..."
    sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token
else
    echo "[WARN-42] /vagrant is not mounted. Skipping token copy."
fi

echo "[INFO-42]  k3s server setup complete."