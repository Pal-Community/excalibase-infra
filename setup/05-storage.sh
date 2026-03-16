#!/bin/bash
# Install local-path provisioner (storage class for PVCs)
# Run on master node before deploying any stateful workloads
set -e

echo "==> Installing local-path provisioner..."
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

echo "==> Setting as default storage class..."
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo "==> Storage class:"
kubectl get sc
