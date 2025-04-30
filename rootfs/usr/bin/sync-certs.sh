#!/bin/bash
# shellcheck shell=bash disable=SC2016,SC2155
set -e

CERT_SECRET_NAME="${CERT_SECRET_NAME:-internal-ca}"
CERT_SECRET_KEY="${CERT_SECRET_KEY:-tls.crt}"
CERT_NAMESPACE="${CERT_NAMESPACE:-cert-manager}"
SYNC_INTERVAL_SECONDS="${SYNC_INTERVAL_SECONDS:-300}"

CERT_DIR="/usr/share/nginx/html/certs"
CERT_PATH="/usr/share/nginx/html/certs/ca-root.pem"

if [[ ! -d "$CERT_DIR" ]]; then
  echo "[sync-certs] Creating certs directory at $CERT_DIR"
  mkdir -p "$CERT_DIR"
fi

while true; do
  SKIP=false
  echo "[sync-certs] Syncing certificate from Kubernetes..."

  if kubectl get --raw=/healthz > /dev/null 2>&1; then
    echo "[sync-certs] Kubernetes API is reachable, fetching cert..."
    echo "[sync-certs] Secret: ${CERT_SECRET_NAME}" Namespace: "${CERT_NAMESPACE}" Key: "${CERT_SECRET_KEY}"
    kubectl get secret "$CERT_SECRET_NAME" -n "$CERT_NAMESPACE" -o jsonpath="{.data.ca\.crt}" | base64 -d > "$CERT_PATH"
  else
    echo "[sync-certs] WARNING: Kubernetes API not reachable, skipping cert sync."
    SKIP=true
  fi

  if [ -f "/usr/share/nginx/html/scripts/install.mobileconfig.tmpl" ] && ! $SKIP; then
    echo "[sync-certs] Regenerating mobileconfig with new cert..."
    export CA_CERT_BASE64="$(base64 -w 0 "$CERT_PATH")"
    envsubst '${PORTAL_DOMAIN} ${CA_CERT_BASE64}' < /usr/share/nginx/html/scripts/install.mobileconfig.tmpl > /usr/share/nginx/html/scripts/install.mobileconfig
  fi

  echo "[sync-certs] Sleeping ${SYNC_INTERVAL_SECONDS} seconds..."
  sleep "$SYNC_INTERVAL_SECONDS"
done
