#!/bin/bash
# Get directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to that directory
cd "$SCRIPT_DIR" || exit

# Check current directory
pwd 

# helm repo add argo https://argoproj.github.io/argo-helm
# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm repo update

# helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --wait --version 8.3.5

# helm upgrade --install prometheus-crds prometheus-community/prometheus-operator-crds \
#   -n monitoring --create-namespace --version 23.0.0 --wait

# kubectl apply -f manager-app.yaml # apply all needed base charts as argocd application
