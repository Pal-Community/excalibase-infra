#!/bin/bash
# UFW Firewall Setup — run on ALL 3 nodes
# Usage: NODE2_IP=<ip> NODE3_IP=<ip> bash 03-firewall.sh

set -e

NODE2_IP=${NODE2_IP:?"NODE2_IP is required"}
NODE3_IP=${NODE3_IP:?"NODE3_IP is required"}

echo "==> Enabling UFW..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing

echo "==> Allowing public ports..."
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 6443/tcp  # Kubernetes API
ufw allow 9345/tcp  # RKE2 node join

echo "==> Allowing inter-node ports (etcd + kubelet + Canal VXLAN)..."
for NODE_IP in "$NODE2_IP" "$NODE3_IP"; do
  ufw allow from $NODE_IP to any port 2379 proto tcp  # etcd client
  ufw allow from $NODE_IP to any port 2380 proto tcp  # etcd peer
  ufw allow from $NODE_IP to any port 10250 proto tcp # kubelet
  ufw allow from $NODE_IP to any port 8472 proto udp  # Canal VXLAN
  ufw allow from $NODE_IP to any port 4789 proto udp  # Canal VXLAN (alt)
done

echo "==> Allowing routed traffic for Canal CNI..."
ufw default allow routed

echo "==> Firewall status:"
ufw status verbose
