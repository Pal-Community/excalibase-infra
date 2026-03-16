#!/bin/bash
# Install Helm — run on master node
set -e

echo "==> Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "==> Helm version:"
helm version
