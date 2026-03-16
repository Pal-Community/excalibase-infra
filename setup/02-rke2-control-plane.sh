#!/bin/bash
# RKE2 Control Plane Node Setup (Node 2 and Node 3)
# All 3 nodes run control-plane + etcd (no dedicated workers)
# Usage: NODE_IP=<this-node-ip> MASTER_IP=<master-ip> TOKEN=<token> bash 02-rke2-control-plane.sh

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
