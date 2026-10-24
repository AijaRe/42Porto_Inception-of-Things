#!/bin/bash

set -e

echo "Deleting all k3d clusters..."
k3d cluster delete --all || true

echo "Removing Docker resources..."
docker system prune -af