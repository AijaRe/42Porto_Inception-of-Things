#!/bin/bash
set -e

echo "Installing dependencies..."
sudo apt-get update

if ! command -v curl &> /dev/null; then
	sudo apt-get install curl -y
fi

if ! command -v docker &> /dev/null; then
	# Uninstall conflicting docker packages
	sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc | cut -f1)
	sudo apt-get install -y docker.io
fi

if ! command k3d &> /dev/null; then
	curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi