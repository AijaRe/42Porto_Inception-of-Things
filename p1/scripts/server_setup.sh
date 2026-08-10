#!/usr/bin/env bash

set -e

echo "===> [gamado-xS] Start provisioning Server Node..."

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install curl -y

echo "===> Intalling K3s"

curl -sfL https://get.k3s.io | sh -
