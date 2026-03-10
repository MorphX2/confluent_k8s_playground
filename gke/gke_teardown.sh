#!/bin/bash
# gke_teardown.sh – Remove the Confluent Platform release and optionally delete
#                   the GKE cluster entirely.
#
# Usage:
#   ./gke_teardown.sh
#   DELETE_CLUSTER=true GKE_CLUSTER=my-cluster ZONE=us-east1-b ./gke_teardown.sh
set -euo pipefail

GCP_PROJECT="${GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
GKE_CLUSTER="${GKE_CLUSTER:-confluent-playground}"
ZONE="${ZONE:-us-central1-a}"
NAMESPACE="${NAMESPACE:-confluent}"
RELEASE="${RELEASE:-confluent-platform-gke}"
DELETE_CLUSTER="${DELETE_CLUSTER:-false}"

if [[ -z "${GCP_PROJECT}" ]]; then
  echo "ERROR: GCP_PROJECT is not set. Run: gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi

# ── 1. Point kubectl at the target cluster ───────────────────────────────────
echo "▶ Fetching credentials for cluster '${GKE_CLUSTER}'…"
gcloud container clusters get-credentials "${GKE_CLUSTER}" \
  --zone="${ZONE}" --project="${GCP_PROJECT}" 2>/dev/null || true

# ── 2. Uninstall the Helm release ────────────────────────────────────────────
echo "▶ Uninstalling Helm release '${RELEASE}'…"
helm uninstall "${RELEASE}" --namespace "${NAMESPACE}" 2>/dev/null || \
  echo "  (release not found, skipping)"

# ── 3. Delete the namespace and remaining CRs ────────────────────────────────
echo "▶ Deleting namespace '${NAMESPACE}'…"
kubectl delete namespace "${NAMESPACE}" --ignore-not-found

# ── 4. Optionally delete the entire GKE cluster ──────────────────────────────
if [[ "${DELETE_CLUSTER}" != "true" ]]; then
  read -r -p "Delete the GKE cluster '${GKE_CLUSTER}' as well? [y/N] " ANSWER
  [[ "${ANSWER}" =~ ^[Yy]$ ]] && DELETE_CLUSTER=true
fi

if [[ "${DELETE_CLUSTER}" == "true" ]]; then
  echo "▶ Deleting GKE cluster '${GKE_CLUSTER}' (this may take a few minutes)…"
  gcloud container clusters delete "${GKE_CLUSTER}" \
    --zone="${ZONE}" \
    --project="${GCP_PROJECT}" \
    --quiet
  echo "✔ Cluster deleted."
else
  echo "  Cluster left intact."
fi

echo "✔ Teardown complete."
