#!/bin/bash
# RKE2 Master Node Setup
# Run this on the FIRST node only
# Server: 185.227.135.251

set -e

NODE_IP="185.227.135.251"

echo "==> Installing RKE2..."
curl -sfL https://get.rke2.io | sh -

echo "==> Configuring RKE2..."
mkdir -p /etc/rancher/rke2
cat > /etc/rancher/rke2/config.yaml << EOF
node-ip: ${NODE_IP}
tls-san:
  - ${NODE_IP}
EOF

echo "==> Starting RKE2..."
systemctl enable rke2-server
systemctl start rke2-server

echo "==> Configuring kubectl..."
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH=$PATH:/var/lib/rancher/rke2/bin
echo 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml' >> ~/.bashrc
echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin' >> ~/.bashrc

echo "==> Node token (needed for worker nodes):"
cat /var/lib/rancher/rke2/server/node-token

echo "==> Done. Check node status:"
kubectl get nodes
