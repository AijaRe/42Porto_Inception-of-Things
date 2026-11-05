#!/bin/bash
set -e

echo "Installing dependencies..."
sudo apt-get update

CLUSTER_NAME="argonauts"

if ! command -v curl > /dev/null; then
	sudo apt-get install curl -y
fi

if ! command -v docker > /dev/null; then
	# Uninstall conflicting docker packages
	#sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc | cut -f1)
	sudo apt-get install -y docker.io
fi

if ! id -nG $USER | grep -q docker; then
	sudo usermod -aG docker $USER
fi

if ! command -v k3d > /dev/null; then
	curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

if ! command -v kubectl > /dev/null; then
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi

if ! sudo k3d cluster list | grep -q "$CLUSTER_NAME"; then
	sudo k3d cluster create "$CLUSTER_NAME"
	export KUBECONFIG="$(sudo k3d kubeconfig write "$CLUSTER_NAME")"
fi

