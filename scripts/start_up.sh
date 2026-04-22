#!/bin/bash
# Set up the kubernetes configuration
kind create cluster -n edcv --kubeconfig ~/.kube/edcv-kind.conf
ln -sf ~/.kube/edcv-kind.conf ~/.kube/config # to use KinD's kubeconfig

# Pull image manually to speed up the whole process and use cache
TRAEFIK_IMAGE="docker.io/traefik:v3.6.13"
docker pull $TRAEFIK_IMAGE
kind load docker-image $TRAEFIK_IMAGE --name edcv

# Install the helm chart for traefik
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install --namespace traefik traefik traefik/traefik --create-namespace -f values.yaml

# Apply the CRD yaml manifest
kubectl apply --server-side --force-conflicts -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/experimental-install.yaml
