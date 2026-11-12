#!/usr/bin/env bash

set -e

echo "===> [gamado-xSW] Start provisioning Worker Node..."

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install curl -y

# 1 GB of swap on disk: RAM stays at 1 GB as the subject advises, but K3s no
# longer freezes the VM for minutes when memory runs out.
if [ ! -f /swapfile ]; then
    echo "===> [gamado-xSW] Creating 1 GB swap file..."
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi
swapon --show | grep -q /swapfile || sudo swapon /swapfile

echo "===> [gamado-xSW] Waiting for K3s token from server..."
for i in $(seq 1 150); do
  [ -f /vagrant/k3s-token ] && break
  if [ "$i" -eq 150 ]; then
    echo "===> [gamado-xSW] No token in /vagrant after 300s. Is gamado-xS provisioned?" >&2
    exit 1
  fi
  sleep 2
done

K3S_TOKEN=$(cat /vagrant/k3s-token)

# Download first: with "curl | sh", a failed download runs an empty script
# that exits 0, and provisioning would wait forever for k3s-agent.
echo "===> [gamado-xSW] Downloading the K3s installer..."
curl -sfL --retry 5 --retry-delay 3 https://get.k3s.io -o /tmp/k3s-install.sh

echo "===> [gamado-xSW] Installing K3s in agent mode"
K3S_URL="https://192.168.56.110:6443" \
  K3S_TOKEN="${K3S_TOKEN}" \
  INSTALL_K3S_EXEC="agent --node-ip=192.168.56.111" sh /tmp/k3s-install.sh

echo "===> [gamado-xSW] Waiting for agent service to be active..."
for i in $(seq 1 60); do
  sudo systemctl is-active --quiet k3s-agent && break
  if [ "$i" -eq 60 ]; then
    echo "===> [gamado-xSW] k3s-agent not active after 120s. Check: sudo journalctl -u k3s-agent" >&2
    exit 1
  fi
  sleep 2
done

echo "===> [gamado-xSW] Worker provisioning complete."
