#!/bin/bash
# Install SonarQube with community branch plugin
set -e

echo "==> Creating sonarqube database and user in CNPG..."
kubectl apply -f db-init.yaml

echo "==> Adding SonarQube Helm repo..."
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update

echo "==> Installing SonarQube..."
helm upgrade --install sonarqube sonarqube/sonarqube \
  --namespace sonarqube \
  --create-namespace \
  --values values.yaml \
  --timeout 10m

echo "==> Done. Access via: https://sonar.excalibase.io"
echo "==> Default credentials: admin / admin (change on first login)"
