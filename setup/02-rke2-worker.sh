#!/bin/bash
# RKE2 Worker/Control-Plane Node Setup
# Run this on node 2 and node 3
# Usage: NODE_IP=<this-node-ip> MASTER_IP=<master-ip> TOKEN=<token> bash 02-rke2-worker.sh

set -e

NODE_IP=${NODE_IP:?"NODE_IP is required"}
MASTER_IP=${MASTER_IP:?"MASTER_IP is required"}
TOKEN=${TOKEN:?"TOKEN is required"}

echo "==> Installing RKE2..."
curl -sfL https://get.rke2.io | sh -

echo "==> Configuring RKE2..."
mkdir -p /etc/rancher/rke2
cat > /etc/rancher/rke2/config.yaml << EOF
server: https://${MASTER_IP}:9345
token: ${TOKEN}
node-ip: ${NODE_IP}
tls-san:
  - ${NODE_IP}
EOF

echo "==> Starting RKE2..."
systemctl enable rke2-server
systemctl start rke2-server

echo "==> Done. Check from master: kubectl get nodes"
