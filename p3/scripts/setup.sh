#!/bin/bash
set -e

echo "===> Installing dependencies..."
sudo apt-get update

CLUSTER_NAME="argonauts"

if ! command -v curl > /dev/null; then
	sudo apt-get install curl -y
fi

if ! command -v docker > /dev/null; then
	# Uninstall conflicting docker packages
	sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc | cut -f1)
	#sudo apt-get install -y docker.io
	# Add Docker's official GPG key:
	sudo apt install ca-certificates curl -y
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	# Add the repository to Apt sources:
	sudo tee /etc/apt/sources.list.d/docker.sources <<-EOF
	Types: deb
	URIs: https://download.docker.com/linux/debian
	Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
	Components: stable
	Architectures: $(dpkg --print-architecture)
	Signed-By: /etc/apt/keyrings/docker.asc
	EOF

	sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	sudo systemctl enable --now docker
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

if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
	k3d cluster create "$CLUSTER_NAME" \
		--port "8080:80@loadbalancer" \
		--port "8443:443@loadbalancer"
fi

if ! [ -f ~/.kube/config ]; then
	mkdir -p ~/.kube
	k3d kubeconfig get argonauts > ~/.kube/config
fi

k3d kubeconfig merge "$CLUSTER_NAME" --kubeconfig-switch-context

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -


echo "===> Setup complete."

