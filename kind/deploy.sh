#!/bin/bash
# deploy.sh – Start Minikube (if needed) and deploy the lightweight
#             Confluent Platform 7.8.0 stack using the local Helm chart.
#
# Docker Desktop RAM limit is ~3.9 GiB, so Control Center is disabled by
# default. To enable it, increase Docker Desktop memory to ≥ 6 GiB first, then:
#   ENABLE_CONTROL_CENTER=true ./deploy.sh
set -euo pipefail

NAMESPACE="${NAMESPACE:-confluent}"
RELEASE="${RELEASE:-confluent-platform}"
CHART_DIR="../helm_charts/confluent-platform"
KIND_CONFIG_YAML="$(pwd)/3-node-kubernetes-cluster.yaml"
ENABLE_CONTROL_CENTER="${ENABLE_CONTROL_CENTER:-false}"
KIND_CLUSTER=$(kind get clusters 2>/dev/null)

# ── 1. Ensure that the Kind cluster is running ────────────────────────────────────────────
if ! echo ${KIND_CLUSTER} | grep -q "confluent" && [ -f "${KIND_CONFIG_YAML}" ]; then
  echo "▶ Creating 3 Node Kind Cluster"
  kind create cluster --name confluent --config $KIND_CONFIG_YAML
  
else
  echo "✔ Kind cluster already running."
fi

# ── 2. Add the Confluent Helm repo ───────────────────────────────────────────
echo "▶ Adding / updating Confluent Helm repository…"
helm repo add confluentinc https://packages.confluent.io/helm 2>/dev/null || true
helm repo update

# ── 3. Resolve chart dependencies (downloads the CFK operator sub-chart) ────
echo "▶ Resolving chart dependencies…"
helm dependency update "${CHART_DIR}"

# ── 4. Deploy ────────────────────────────────────────────────────────────────
echo "▶ Installing / upgrading release '${RELEASE}' in namespace '${NAMESPACE}'…"
helm upgrade --install "${RELEASE}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --disable-openapi-validation \
  --set "controlcenter.enabled=${ENABLE_CONTROL_CENTER}" \
  --wait \
  --timeout 10m

echo ""
echo "✔ Confluent Platform deployed!"
echo ""
if [[ "${ENABLE_CONTROL_CENTER}" == "true" ]]; then
  echo "  To open Control Center in your browser, run:"
  echo "    kubectl port-forward svc/controlcenter 9021:9021 -n ${NAMESPACE}"
  echo "  Then visit: http://localhost:9021"
  echo ""
fi
echo "  Kafka bootstrap (inside cluster): kafka.${NAMESPACE}.svc.cluster.local:9092"
echo ""
echo "  Note: Control Center is disabled by default (Docker Desktop RAM limit)."
echo "  To enable: ENABLE_CONTROL_CENTER=true ./deploy.sh"
echo "  (First increase Docker Desktop memory to ≥ 6 GiB in Docker settings)"
