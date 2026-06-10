#!/usr/bin/env bash
set -euo pipefail

RG=${RG:-luis-agentic-demo-rg}
AKS=${AKS:-luis-agentic-demo-aks}
AZURE_DNS_LABEL=${AZURE_DNS_LABEL:-luis-agentic-demo}
LOCATION=${LOCATION:-westeurope}

echo "Applying Terraform infrastructure..."

terraform -chdir=infra init
terraform -chdir=infra fmt
terraform -chdir=infra validate
terraform -chdir=infra plan
terraform -chdir=infra apply -auto-approve

echo "Getting AKS credentials..."

az aks get-credentials \
  --resource-group "$RG" \
  --name "$AKS" \
  --overwrite-existing

echo "Current Kubernetes context:"
kubectl config current-context

echo "Checking AKS nodes..."
kubectl get nodes

echo "Installing Gateway API CRDs..."

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml

echo "Installing Traefik..."

helm repo add traefik https://traefik.github.io/charts || true
helm repo update

helm upgrade --install --namespace traefik traefik traefik/traefik \
  --create-namespace \
  -f values.yaml \
  --wait \
  --timeout 5m

echo "Waiting for Traefik LoadBalancer IP..."

kubectl wait --namespace traefik \
  --for=jsonpath='{.status.loadBalancer.ingress[0].ip}' service/traefik \
  --timeout=600s

JAD_IP=$(kubectl get svc -n traefik traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
JAD_HOST="${AZURE_DNS_LABEL}.${LOCATION}.cloudapp.azure.com"

echo "Traefik IP: $JAD_IP"
echo "Traefik hostname: $JAD_HOST"

echo "Checking DNS resolution..."

for i in {1..30}; do
  if nslookup "$JAD_HOST" >/dev/null 2>&1; then
    echo "DNS resolved successfully."
    break
  fi

  echo "Waiting for DNS to resolve..."
  sleep 10
done

echo "Installing cert-manager..."
helm repo add jetstack https://charts.jetstack.io || true
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --set config.apiVersion="controller.config.cert-manager.io/v1alpha1" \
  --set config.kind="ControllerConfiguration" \
  --set config.enableGatewayAPI=true \
  --wait \
  --timeout 5m

echo "Deploying base infrastructure..."

kubectl apply -k k8s/base/

echo "Waiting for infrastructure pods..."

kubectl wait --namespace edc-v \
  --for=condition=ready pod \
  --selector=type=edcv-infra \
  --timeout=300s

kubectl wait --namespace edc-v \
  --for=condition=available deployment \
  --all \
  --timeout=300s

kubectl wait --namespace edc-v \
  --for=condition=complete job \
  --all \
  --timeout=300s

echo "Deploying applications..."

kubectl apply -k k8s/apps/

echo "Waiting for deployments to become available..."

kubectl wait --namespace edc-v \
  --for=condition=available deployment \
  --all \
  --timeout=300s

echo "Waiting for seed jobs to complete..."

kubectl wait --namespace edc-v \
  --for=condition=complete job \
  --all \
  --timeout=300s

echo ""
echo "Deployment complete."
echo "Demo URL:"
echo "https://${JAD_HOST}"
