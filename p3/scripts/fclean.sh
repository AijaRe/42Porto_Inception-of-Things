#!/bin/bash
set -e

echo "===> Removing k3d clusters if present..."
if command -v k3d > /dev/null; then
	k3d cluster delete --all || true
fi

echo "===> Removing k3d binary..."
sudo rm -f /usr/local/bin/k3d

echo "===> Removing kubectl binary..."
sudo rm -f /usr/local/bin/kubectl

echo "===> Stopping Docker services..."
sudo systemctl stop docker 2>/dev/null || true
sudo systemctl stop docker.socket 2>/dev/null || true
sudo systemctl disable docker 2>/dev/null || true
sudo systemctl disable docker.socket 2>/dev/null || true

echo "===> Purging Docker packages..."
DOCKER_PACKAGES="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io docker-compose docker-doc docker-buildx podman-docker runc"
for pkg in $DOCKER_PACKAGES; do
	if dpkg -s "$pkg" > /dev/null 2>&1; then
		sudo apt-get purge -y "$pkg"
	fi
done

echo "===> Removing Docker data and configuration..."
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /etc/docker
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/sources.list.d/docker.sources
sudo rm -f /etc/apt/keyrings/docker.asc


echo "===> Full cleanup complete."