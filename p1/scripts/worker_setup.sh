#!/usr/bin/env bash

set -e

echo "===> [gamado-xSW] Start provisioning Worker Node..."

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install curl -y

echo "===> [gamado-xSW] Waiting for K3s token from server..."
until [ -f /vagrant/k3s-token ]; do
  sleep 2
done

K3S_TOKEN=$(cat /vagrant/k3s-token)

echo "===> [gamado-xSW] Installing K3s in agent mode"

curl -sfL https://get.k3s.io | K3S_URL="https://192.168.56.110:6443" \
  K3S_TOKEN="${K3S_TOKEN}" \
  INSTALL_K3S_EXEC="agent --node-ip=192.168.56.111" sh -

echo "===> [gamado-xSW] Waiting for agent service to be active..."
until sudo systemctl is-active --quiet k3s-agent; do
  sleep 2
done

echo "===> [gamado-xSW] Worker provisioning complete."