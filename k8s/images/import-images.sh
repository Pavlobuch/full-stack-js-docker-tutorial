#!/usr/bin/env bash
set -euo pipefail

# Import locally-built Docker images into k3s containerd.
# Needed because k3s uses containerd and cannot see Docker daemon images.

IMAGES=(
  "finished-api:latest"
  "finished-ui:latest"
  "finished-nginx:latest"
)

for img in "${IMAGES[@]}"; do
  echo "==> Importing image into k3s containerd: ${img}"
  tmp="/tmp/${img//[:\/]/_}.tar"

  if ! docker image inspect "${img}" >/dev/null 2>&1; then
    echo "ERROR: Docker image not found locally: ${img}"
    echo "Build it first (e.g. docker compose build) then re-run."
    exit 1
  fi

  docker save "${img}" -o "${tmp}"
  sudo k3s ctr images import "${tmp}"
done

echo "==> Images in k3s containerd:"
sudo k3s ctr images ls | egrep 'finished-api' || true
