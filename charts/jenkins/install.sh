#!/bin/bash
# Install Jenkins
set -e

echo "==> Adding Jenkins Helm repo..."
helm repo add jenkins https://charts.jenkins.io
helm repo update

echo "==> Installing Jenkins..."
helm upgrade --install jenkins jenkins/jenkins \
  --namespace jenkins \
  --create-namespace \
  --values values.yaml

echo "==> Waiting for Jenkins..."
kubectl rollout status statefulset/jenkins -n jenkins

echo "==> Get admin password:"
echo "kubectl exec -n jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password"
echo "==> Access via: https://jenkins.excalibase.io"
