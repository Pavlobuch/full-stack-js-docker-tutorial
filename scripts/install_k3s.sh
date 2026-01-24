#!/usr/bin/env bash
set -euo pipefail

# Idempotent install: do nothing if already installed
if command -v k3s >/dev/null 2>&1; then
  echo "K3s already installed: $(k3s --version)"
  exit 0
fi

# Minimal deps (Amazon Linux 2023 typically already has curl)
sudo dnf -y install curl || true

# Install K3s (single-node, bundled containerd)
curl -sfL https://get.k3s.io | sudo sh -

# Enable kubectl for root (k3s bundles kubectl)
sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl

# Make kubeconfig readable for ops (optional; you can keep root-only if you prefer)
sudo chmod 0644 /etc/rancher/k3s/k3s.yaml

echo "K3s installed OK"
sudo systemctl status k3s --no-pager || true
