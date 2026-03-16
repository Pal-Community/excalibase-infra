#!/bin/bash
# Install CNPG operator and deploy PostgreSQL cluster
set -e

echo "==> Adding CNPG Helm repo..."
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

echo "==> Installing CNPG operator..."
helm upgrade --install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system \
  --create-namespace

echo "==> Waiting for CNPG operator..."
kubectl rollout status deployment/cnpg-cloudnative-pg -n cnpg-system

echo "==> Creating namespace..."
kubectl create namespace postgres --dry-run=client -o yaml | kubectl apply -f -

echo "==> Creating S3 backup credentials secret..."
kubectl create secret generic cnpg-s3-creds \
  --from-literal=ACCESS_KEY_ID="${S3_ACCESS_KEY}" \
  --from-literal=SECRET_ACCESS_KEY="${S3_SECRET_KEY}" \
  --namespace postgres \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Deploying PostgreSQL cluster..."
kubectl apply -f cluster.yaml -n postgres

echo "==> Watch cluster status:"
echo "kubectl get cluster -n postgres"
