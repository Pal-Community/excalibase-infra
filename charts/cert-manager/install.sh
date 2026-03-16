#!/bin/bash
# Install cert-manager with Let's Encrypt for *.excalibase.io
set -e

echo "==> Adding cert-manager Helm repo..."
helm repo add jetstack https://charts.jetstack.io
helm repo update

echo "==> Installing cert-manager..."
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.5 \
  --set installCRDs=true

echo "==> Waiting for cert-manager to be ready..."
kubectl rollout status deployment/cert-manager -n cert-manager

echo "==> Applying ClusterIssuer..."
kubectl apply -f clusterissuer.yaml

echo "==> Done. Cert-manager will auto-issue certs for *.excalibase.io via ingress annotations."
