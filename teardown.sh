#!/bin/bash
# teardown.sh – Remove the Confluent Platform release and optionally stop Minikube.
set -euo pipefail

NAMESPACE="${NAMESPACE:-confluent}"
RELEASE="${RELEASE:-confluent-platform}"

echo "▶ Uninstalling Helm release '${RELEASE}'…"
helm uninstall "${RELEASE}" --namespace "${NAMESPACE}" 2>/dev/null || \
  echo "  (release not found, skipping)"

echo "▶ Deleting namespace '${NAMESPACE}'…"
kubectl delete namespace "${NAMESPACE}" --ignore-not-found

read -r -p "Stop Minikube as well? [y/N] " STOP_MINIKUBE
if [[ "${STOP_MINIKUBE}" =~ ^[Yy]$ ]]; then
  echo "▶ Stopping Minikube…"
  minikube stop
fi

echo "✔ Teardown complete."
