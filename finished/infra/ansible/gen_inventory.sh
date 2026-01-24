#!/usr/bin/env bash
set -euo pipefail

# Paths (adjust only if your repo layout differs)
TF_DIR="${TF_DIR:-../terraform/envs/dev}"
OUT_FILE="${OUT_FILE:-inventory.ini}"

# SSH settings
SSH_USER="${SSH_USER:-ec2-user}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/cheap-fullstack}"

# Read outputs from Terraform
BASTION_IP="$(terraform -chdir="$TF_DIR" output -raw bastion_public_ip 2>/dev/null || true)"
APP_IP="$(terraform -chdir="$TF_DIR" output -raw app_private_ip 2>/dev/null || true)"

if [[ -z "${BASTION_IP}" || -z "${APP_IP}" ]]; then
  echo "ERROR: Could not read Terraform outputs."
  echo "Check that you ran: terraform -chdir=${TF_DIR} apply"
  echo "And that outputs exist: bastion_public_ip, app_private_ip"
  exit 1
fi

# Generate inventory.ini
cat > "${OUT_FILE}" <<EOF
[app]
app1 ansible_host=${APP_IP}

[all:vars]
ansible_user=${SSH_USER}
ansible_ssh_private_key_file=${SSH_KEY}
ansible_ssh_common_args=-o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -i ${SSH_KEY} -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ${SSH_USER}@${BASTION_IP}"
EOF

echo "✅ Wrote ${OUT_FILE}"
echo "  bastion_public_ip=${BASTION_IP}"
echo "  app_private_ip=${APP_IP}"
