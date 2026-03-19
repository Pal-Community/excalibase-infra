#!/bin/bash
set -e

echo "==> Installing ArgoCD..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values values.yaml \
  --timeout 10m

echo "==> Waiting for ArgoCD server to be ready..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=5m

echo "==> Getting initial admin password..."
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

echo "==> Done. Access via: https://argocd.excalibase.io"
echo "==> Username: admin"
