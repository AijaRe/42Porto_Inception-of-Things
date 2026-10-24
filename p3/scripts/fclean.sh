#!/bin/bash
# Uninstall docker packages
sudo systemctl stop docker
sudo apt-get purge -y docker.io
sudo apt-get autoremove -y
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker

# Remove k3d
sudo rm -f /usr/local/bin/k3d