#!/bin/bash
# Install monitoring stack: Prometheus + Grafana + Loki + Promtail
set -e

echo "==> Adding Helm repos..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo "==> Installing kube-prometheus-stack..."
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values values-prometheus.yaml

echo "==> Installing Loki + Promtail..."
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --values values-loki.yaml

echo "==> Waiting for Grafana..."
kubectl rollout status deployment/monitoring-grafana -n monitoring

echo "==> Done."
echo "==> Grafana: https://grafana.excalibase.io"
echo "==> Default password set in values-prometheus.yaml"
