#!/bin/bash
# gke_deploy.sh – Install / upgrade Confluent Platform on an existing GKE cluster.
#
# Usage:
#   ./gke_deploy.sh
#   GKE_CLUSTER=my-cluster ZONE=us-east1-b NAMESPACE=confluent ./gke_deploy.sh
#
# Prerequisites:
#   1. Run ./gke_env_prep.sh to verify tooling.
#   2. Run ./provision_gke.sh to create the GKE cluster (or point kubeconfig at
#      an existing cluster with: gcloud container clusters get-credentials ...).
set -euo pipefail

# ── Configuration (override via environment variables) ───────────────────────
GCP_PROJECT="${GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
GKE_CLUSTER="${GKE_CLUSTER:-confluent-playground}"
ZONE="${ZONE:-us-central1-a}"
NAMESPACE="${NAMESPACE:-confluent}"
RELEASE="${RELEASE:-confluent-platform-gke}"
CHART_DIR="$(cd "$(dirname "$0")/helm_charts/confluent-platform-gke" && pwd)"

if [[ -z "${GCP_PROJECT}" ]]; then
  echo "ERROR: GCP_PROJECT is not set. Run: gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi

# ── 1. Point kubectl at the target cluster ───────────────────────────────────
echo "▶ Fetching credentials for cluster '${GKE_CLUSTER}' in zone '${ZONE}'…"
gcloud container clusters get-credentials "${GKE_CLUSTER}" \
  --zone="${ZONE}" --project="${GCP_PROJECT}"

# ── 2. Add / update the Confluent Helm repo ──────────────────────────────────
echo "▶ Adding / updating Confluent Helm repository…"
helm repo add confluentinc https://packages.confluent.io/helm 2>/dev/null || true
helm repo update

# ── 3. Resolve chart dependencies ────────────────────────────────────────────
echo "▶ Resolving chart dependencies…"
helm dependency update "${CHART_DIR}"

# ── 4. Deploy ────────────────────────────────────────────────────────────────
echo "▶ Installing / upgrading release '${RELEASE}' in namespace '${NAMESPACE}'…"
helm upgrade --install "${RELEASE}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --wait \
  --timeout 15m

# ── 5. Print summary ─────────────────────────────────────────────────────────
echo ""
echo "✔ Confluent Platform deployed to GKE cluster '${GKE_CLUSTER}'!"
echo ""
echo "  Cluster context : $(kubectl config current-context)"
echo "  Namespace       : ${NAMESPACE}"
echo ""
echo "  Check component status:"
echo "    kubectl get confluent -n ${NAMESPACE}"
echo ""
echo "  Access Control Center (port-forward fallback):"
echo "    kubectl port-forward svc/controlcenter 9021:9021 -n ${NAMESPACE}"
echo "    → http://localhost:9021"
echo ""
echo "  Or get the Internal Load Balancer IP:"
echo "    kubectl get svc controlcenter-bootstrap-lb -n ${NAMESPACE}"
