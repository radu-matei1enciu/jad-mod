#!/usr/bin/env bash
set -Eeuo pipefail

# Ordered JAD deployment script
# Run this from the root of the JAD repository.
#
# Optional variables:
#   NS=edc-v WAIT_SECONDS=1800 ./deploy-jad-ordered.sh
#   RERUN_SEED_JOBS=0 ./deploy-jad-ordered.sh

NS="${NS:-edc-v}"
BASE_DIR="${BASE_DIR:-k8s/base}"
APPS_DIR="${APPS_DIR:-k8s/apps}"
WAIT_SECONDS="${WAIT_SECONDS:-1800}"
CURL_IMAGE="${CURL_IMAGE:-curlimages/curl:latest}"
RERUN_SEED_JOBS="${RERUN_SEED_JOBS:-1}"

log() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

error_report() {
  echo
  echo "Deployment failed. Current status:"
  kubectl get pods -n "$NS" -o wide 2>/dev/null || true
  echo
  kubectl get jobs -n "$NS" 2>/dev/null || true
  echo
  kubectl get deployments -n "$NS" 2>/dev/null || true
}

trap error_report ERR

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1"
    exit 1
  }
}

require_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "Missing required file: $file"
    echo "Make sure you run this script from the root of the JAD repository."
    exit 1
  fi
}

apply_file() {
  local file="$1"
  require_file "$file"
  echo "+ kubectl apply -f $file"
  kubectl apply -f "$file"
}

wait_deployment() {
  local deployment="$1"

  log "Waiting for deployment/$deployment rollout"
  kubectl rollout status "deployment/$deployment" -n "$NS" --timeout="${WAIT_SECONDS}s"
}

wait_pods_ready_selector() {
  local selector="$1"

  log "Waiting for pods to exist: selector=$selector"

  local elapsed=0
  while true; do
    local count
    count=$(kubectl get pods -n "$NS" -l "$selector" --no-headers 2>/dev/null | wc -l | tr -d ' ')

    if [ "$count" -gt 0 ]; then
      break
    fi

    if [ "$elapsed" -ge "$WAIT_SECONDS" ]; then
      echo "Timed out waiting for pods with selector=$selector to exist"
      kubectl get pods -n "$NS" -o wide || true
      exit 1
    fi

    sleep 3
    elapsed=$((elapsed + 3))
  done

  log "Waiting for pods Ready: selector=$selector"
  kubectl wait -n "$NS" --for=condition=Ready pod -l "$selector" --timeout="${WAIT_SECONDS}s"
}

wait_http() {
  local name="$1"
  local url="$2"
  local pod="wait-${name}-$(date +%s)-$RANDOM"

  log "Waiting for HTTP endpoint: $url"

  kubectl run "$pod" \
    -n "$NS" \
    --image="$CURL_IMAGE" \
    --restart=Never \
    --rm \
    -i \
    --attach \
    --command -- sh -ec "
      end=\$((\$(date +%s)+$WAIT_SECONDS))
      until curl -fsS --max-time 8 '$url' >/dev/null; do
        if [ \$(date +%s) -ge \$end ]; then
          echo 'Timed out waiting for $url'
          exit 1
        fi
        echo 'Still waiting for $url ...'
        sleep 5
      done
      echo 'Ready: $url'
    "
}

wait_job_complete() {
  local job="$1"
  local start now elapsed succeeded failed active

  log "Waiting for job/$job to complete"
  start=$(date +%s)

  until kubectl get job "$job" -n "$NS" >/dev/null 2>&1; do
    now=$(date +%s)
    elapsed=$((now - start))
    if [ "$elapsed" -ge "$WAIT_SECONDS" ]; then
      echo "Timed out waiting for job/$job to be created"
      exit 1
    fi
    echo "Waiting for job/$job object to exist..."
    sleep 3
  done

  while true; do
    succeeded=$(kubectl get job "$job" -n "$NS" -o jsonpath='{.status.succeeded}' 2>/dev/null || true)
    failed=$(kubectl get job "$job" -n "$NS" -o jsonpath='{.status.failed}' 2>/dev/null || true)
    active=$(kubectl get job "$job" -n "$NS" -o jsonpath='{.status.active}' 2>/dev/null || true)

    if [ "${succeeded:-0}" = "1" ]; then
      echo "job/$job completed successfully"
      echo "Last logs from job/$job:"
      kubectl logs -n "$NS" "job/$job" --all-containers --tail=120 || true
      return 0
    fi

    if [ -n "${failed:-}" ] && [ "${failed}" != "0" ]; then
      echo "job/$job failed"
      kubectl describe job "$job" -n "$NS" || true
      kubectl logs -n "$NS" "job/$job" --all-containers --tail=200 || true
      exit 1
    fi

    now=$(date +%s)
    elapsed=$((now - start))
    if [ "$elapsed" -ge "$WAIT_SECONDS" ]; then
      echo "Timed out waiting for job/$job"
      echo "active=${active:-0}, succeeded=${succeeded:-0}, failed=${failed:-0}"
      kubectl describe job "$job" -n "$NS" || true
      kubectl logs -n "$NS" "job/$job" --all-containers --tail=200 || true
      exit 1
    fi

    sleep 5
  done
}

apply_seed_job() {
  local file="$1"
  local job="$2"

  log "Applying seed job: $job"

  if [ "$RERUN_SEED_JOBS" = "1" ]; then
    kubectl delete job "$job" -n "$NS" --ignore-not-found
  fi

  apply_file "$file"
  wait_job_complete "$job"
}

preflight() {
  log "Preflight checks"
  require_cmd kubectl
  kubectl config current-context
  kubectl version --client=true

  require_file "$BASE_DIR/edcv-namespace.yaml"
  require_file "$BASE_DIR/gateway-class.yaml"
  require_file "$BASE_DIR/gateway.yaml"
  require_file "$BASE_DIR/postgres.yaml"
  require_file "$BASE_DIR/keycloak.yaml"
  require_file "$BASE_DIR/vault.yaml"
  require_file "$BASE_DIR/nats.yaml"

  require_file "$APPS_DIR/controlplane.yaml"
  require_file "$APPS_DIR/dataplane.yaml"
  require_file "$APPS_DIR/identityhub.yaml"
  require_file "$APPS_DIR/issuerservice.yaml"
  require_file "$APPS_DIR/redline.yaml"
}

preflight

log "1/10 Namespace and Gateway"
apply_file "$BASE_DIR/edcv-namespace.yaml"
apply_file "$BASE_DIR/gateway-class.yaml"
apply_file "$BASE_DIR/gateway.yaml"

log "2/10 PostgreSQL"
apply_file "$BASE_DIR/postgres.yaml"
wait_deployment "postgres"

log "3/10 Keycloak"
apply_file "$BASE_DIR/keycloak.yaml"
wait_deployment "keycloak"
wait_http "keycloak-edcv-realm" "http://keycloak.edc-v.svc.cluster.local:8080/realms/edcv/.well-known/openid-configuration"

log "4/10 Vault and Vault bootstrap"
apply_file "$BASE_DIR/vault.yaml"
wait_deployment "vault"
wait_job_complete "vault-bootstrap"

log "5/10 NATS and observability"
apply_file "$BASE_DIR/nats.yaml"
wait_deployment "nats"

apply_file "$BASE_DIR/jaeger.yaml"
apply_file "$BASE_DIR/loki.yaml"
apply_file "$BASE_DIR/prometheus.yaml"
apply_file "$BASE_DIR/grafana.yaml"

wait_deployment "jaeger"
wait_deployment "loki"
wait_deployment "prometheus"
wait_deployment "grafana"

log "6/10 Application ConfigMaps"
apply_file "$APPS_DIR/telemetry-config.yaml"
apply_file "$APPS_DIR/controlplane-config.yaml"
apply_file "$APPS_DIR/dataplane-config.yaml"
apply_file "$APPS_DIR/identityhub-config.yaml"
apply_file "$APPS_DIR/issuerservice-config.yaml"
apply_file "$APPS_DIR/provision-manager-config.yaml"
apply_file "$APPS_DIR/tenant-manager-config.yaml"
apply_file "$APPS_DIR/edcv-agent-config.yaml"
apply_file "$APPS_DIR/keycloak-agent-config.yaml"
apply_file "$APPS_DIR/onboarding-agent-config.yaml"
apply_file "$APPS_DIR/registration-agent-config.yaml"
apply_file "$APPS_DIR/redline-config.yaml"
apply_file "$APPS_DIR/ui-config.yaml"
apply_file "$APPS_DIR/siglet-config.yaml"

log "7/10 Core EDC-V services"
apply_file "$APPS_DIR/controlplane.yaml"
wait_deployment "controlplane"

apply_file "$APPS_DIR/dataplane.yaml"
wait_deployment "dataplane"

apply_file "$APPS_DIR/identityhub.yaml"
wait_deployment "identityhub"

apply_file "$APPS_DIR/issuerservice.yaml"
wait_deployment "issuerservice"
wait_http "issuerservice-readiness" "http://issuerservice.edc-v.svc.cluster.local:10010/api/check/readiness"

log "8/10 CFM managers, agents, Siglet, Redline"
apply_file "$APPS_DIR/provision-manager.yaml"
apply_file "$APPS_DIR/tenant-manager.yaml"

wait_deployment "cfm-provision-manager"
wait_deployment "cfm-tenant-manager"

apply_file "$APPS_DIR/cfm-agents.yaml"
wait_deployment "cfm-agents"

apply_file "$APPS_DIR/siglet.yaml"
wait_deployment "siglet"

apply_file "$APPS_DIR/redline.yaml"
wait_deployment "redline"
wait_http "redline-health" "http://redline.edc-v.svc.cluster.local:8081/api/public/health"

log "9/10 Seed jobs in dependency order"
apply_seed_job "$APPS_DIR/issuerservice-seed-job.yaml" "issuerservice-seed"
apply_seed_job "$APPS_DIR/provision-manager-seed-job.yaml" "provision-manager-seed"
apply_seed_job "$APPS_DIR/tenant-manager-seed-job.yaml" "tenant-manager-seed"
apply_seed_job "$APPS_DIR/redline-seed-job.yaml" "redline-seed"

log "10/10 UI"
apply_file "$APPS_DIR/ui.yaml"
wait_deployment "jad-web-ui"

log "Final status"
kubectl get pods -n "$NS" -o wide
echo
kubectl get jobs -n "$NS"
echo
kubectl get deployments -n "$NS"

echo
echo "JAD deployment completed successfully."
echo "Namespace: $NS"
echo "Tip: if this fails after a previous partial deployment, clean the cluster/namespace and run again."
