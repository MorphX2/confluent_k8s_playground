#!/bin/bash
# provision_gke.sh – Create a GKE Standard cluster sized for Confluent Platform.
#
# Usage:
#   ./provision_gke.sh                  # uses defaults below
#   GKE_CLUSTER=my-cluster ZONE=us-east1-b ./provision_gke.sh
#
# Required env (or edit defaults below):
#   GCP_PROJECT   – GCP project ID  (falls back to active gcloud project)
#   GKE_CLUSTER   – cluster name
#   ZONE          – GCP zone
set -euo pipefail

# ── Defaults (override via environment variables) ────────────────────────────
GCP_PROJECT="${GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
GKE_CLUSTER="${GKE_CLUSTER:-confluent-playground}"
ZONE="${ZONE:-us-central1-a}"
NODE_MACHINE_TYPE="${NODE_MACHINE_TYPE:-e2-standard-4}"   # 4 vCPU / 16 GB
NUM_NODES="${NUM_NODES:-3}"                               # one node per replica
DISK_SIZE_GB="${DISK_SIZE_GB:-50}"
K8S_VERSION="${K8S_VERSION:-latest}"
NAMESPACE="${NAMESPACE:-confluent}"

if [[ -z "${GCP_PROJECT}" ]]; then
  echo "ERROR: GCP_PROJECT is not set and no default gcloud project is configured."
  echo "       Run: gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi

echo "▶ Provisioning GKE cluster '${GKE_CLUSTER}'"
echo "  Project : ${GCP_PROJECT}"
echo "  Zone    : ${ZONE}"
echo "  Nodes   : ${NUM_NODES} × ${NODE_MACHINE_TYPE} (${DISK_SIZE_GB} GB SSD each)"
echo ""

# ── 1. Enable required GCP APIs ─────────────────────────────────────────────
echo "▶ Enabling GCP APIs (container, compute)…"
gcloud services enable container.googleapis.com compute.googleapis.com \
  --project="${GCP_PROJECT}"

# ── 2. Create the cluster ────────────────────────────────────────────────────
if gcloud container clusters describe "${GKE_CLUSTER}" \
     --zone="${ZONE}" --project="${GCP_PROJECT}" &>/dev/null; then
  echo "✔ Cluster '${GKE_CLUSTER}' already exists, skipping creation."
else
  echo "▶ Creating cluster (this takes ~5 minutes)…"
  gcloud container clusters create "${GKE_CLUSTER}" \
    --project="${GCP_PROJECT}" \
    --zone="${ZONE}" \
    --cluster-version="${K8S_VERSION}" \
    --machine-type="${NODE_MACHINE_TYPE}" \
    --num-nodes="${NUM_NODES}" \
    --disk-type=pd-ssd \
    --disk-size="${DISK_SIZE_GB}" \
    --enable-ip-alias \
    --no-enable-basic-auth \
    --metadata disable-legacy-endpoints=true \
    --workload-pool="${GCP_PROJECT}.svc.id.goog"
fi

# ── 3. Fetch credentials so kubectl is pointed at the new cluster ────────────
echo "▶ Fetching cluster credentials…"
gcloud container clusters get-credentials "${GKE_CLUSTER}" \
  --zone="${ZONE}" --project="${GCP_PROJECT}"

# ── 4. Verify connectivity ───────────────────────────────────────────────────
echo "▶ Verifying cluster connectivity…"
kubectl cluster-info

echo ""
echo "✔ GKE cluster '${GKE_CLUSTER}' is ready."
echo "  Next step: run ./gke_deploy.sh to install Confluent Platform."
