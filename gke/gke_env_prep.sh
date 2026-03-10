#!/bin/bash
# gke_env_prep.sh – Verify all required tools are present before deploying
#                   Confluent Platform to GKE.
set -euo pipefail

PASS=true

check() {
  local cmd="$1"
  local hint="$2"
  if ! command -v "${cmd}" &>/dev/null; then
    echo "✗ '${cmd}' not found. ${hint}"
    PASS=false
  else
    echo "✔ ${cmd} ($(${cmd} version --short 2>/dev/null || ${cmd} version 2>/dev/null | head -1))"
  fi
}

echo "── Checking required tools ──────────────────────────────────────────"

# gcloud CLI
if ! command -v gcloud &>/dev/null; then
  echo "✗ 'gcloud' not found. Install the Google Cloud SDK:"
  echo "    https://cloud.google.com/sdk/docs/install"
  PASS=false
else
  echo "✔ gcloud ($(gcloud version 2>/dev/null | head -1))"
fi

# kubectl
if ! command -v kubectl &>/dev/null; then
  echo "✗ 'kubectl' not found. Install via: gcloud components install kubectl"
  PASS=false
else
  echo "✔ kubectl ($(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1))"
fi

# helm ≥ 3
if ! command -v helm &>/dev/null; then
  echo "✗ 'helm' not found. Install from https://helm.sh/docs/intro/install/"
  PASS=false
else
  HELM_MAJOR=$(helm version --short 2>/dev/null | grep -oE 'v[0-9]+' | head -1 | sed 's/v//')
  if [[ "${HELM_MAJOR}" -lt 3 ]]; then
    echo "✗ Helm version 3 or higher is required. Found: $(helm version --short)"
    PASS=false
  else
    echo "✔ helm ($(helm version --short))"
  fi
fi

# gke-gcloud-auth-plugin (required for kubectl ≥ 1.26 + GKE)
if ! command -v gke-gcloud-auth-plugin &>/dev/null; then
  echo "✗ 'gke-gcloud-auth-plugin' not found."
  echo "    Install via: gcloud components install gke-gcloud-auth-plugin"
  PASS=false
else
  echo "✔ gke-gcloud-auth-plugin"
fi

echo "── Checking gcloud authentication ──────────────────────────────────"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
  echo "✗ No active gcloud account found. Run: gcloud auth login"
  PASS=false
else
  ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
  echo "✔ Authenticated as: ${ACTIVE_ACCOUNT}"
fi

echo "── Checking gcloud project ──────────────────────────────────────────"
PROJECT=$(gcloud config get-value project 2>/dev/null || true)
if [[ -z "${PROJECT}" ]]; then
  echo "✗ No default project set. Run: gcloud config set project YOUR_PROJECT_ID"
  PASS=false
else
  echo "✔ Active project: ${PROJECT}"
fi

echo "────────────────────────────────────────────────────────────────────"
if [[ "${PASS}" == "true" ]]; then
  echo "✔ All checks passed. You are ready to deploy to GKE."
else
  echo "✗ One or more checks failed. Please resolve the issues above."
  exit 1
fi
