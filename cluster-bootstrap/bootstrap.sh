#!/bin/bash

helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --wait

helm upgrade helm install prometheus-crds prometheus-community/prometheus-operator-crds \
  --namespace monitoring --create-namespace --version 23.0.0 --wait

kubectl apply -f ./manager-app.yaml # apply all needed base charts as argocd application