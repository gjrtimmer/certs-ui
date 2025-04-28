#!/bin/sh
# shellcheck shell=bash disable=SC2016,SC2155
set -e

CERT_SECRET_NAME="${CERT_SECRET_NAME:-internal-ca}"
CERT_SECRET_KEY="${CERT_SECRET_KEY:-tls.crt}"
CERT_NAMESPACE="${CERT_NAMESPACE:-cert-manager}"
SYNC_INTERVAL_SECONDS="${SYNC_INTERVAL_SECONDS:-300}"

CERT_PATH="/usr/share/nginx/html/certs/ca-root.pem"

while true; do
  echo "[sync-certs] Syncing certificate from Kubernetes..."

  kubectl get secret "$CERT_SECRET_NAME" -n "$CERT_NAMESPACE" -o jsonpath="{.data.${CERT_SECRET_KEY}}" | base64 -d > "$CERT_PATH"

  if [ -f /usr/share/nginx/html/scripts/install.mobileconfig.tmpl ]; then
    echo "[sync-certs] Regenerating mobileconfig with new cert..."
    export CA_CERT_BASE64="$(base64 -w 0 "$CERT_PATH")"
    envsubst '${PORTAL_DOMAIN} ${CA_CERT_BASE64}' < /usr/share/nginx/html/scripts/install.mobileconfig.tmpl > /usr/share/nginx/html/scripts/install.mobileconfig
  fi

  echo "[sync-certs] Sleeping ${SYNC_INTERVAL_SECONDS} seconds..."
  sleep "$SYNC_INTERVAL_SECONDS"
done
