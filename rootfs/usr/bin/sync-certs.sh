#!/bin/bash
# shellcheck shell=bash disable=SC2016,SC2155
set -e

CERT_NAMESPACE="${CERT_NAMESPACE:-cert-manager}"
SYNC_INTERVAL_SECONDS="${SYNC_INTERVAL_SECONDS:-300}"
CERT_LIST_JSON="${CERT_LIST_JSON:-[]}"

CERT_DIR="/usr/share/nginx/html/certs"

if [[ ! -d "$CERT_DIR" ]]; then
  echo "[sync-certs] Creating certs directory at $CERT_DIR"
  mkdir -p "$CERT_DIR"
fi

while true; do
  SKIP=false
  echo "[sync-certs] Syncing all certificates from Kubernetes..."

  if kubectl get --raw=/healthz > /dev/null 2>&1; then
    echo "[sync-certs] Kubernetes API is reachable, fetching certs..."
    echo -n > "$CERT_DIR/chain.pem"
    echo "$CERT_LIST_JSON" | jq -c '.[]' | while read -r cert; do
      NAME=$(echo "$cert" | jq -r '.name')
      SECRET=$(echo "$cert" | jq -r '.secretName')
      KEY=$(echo "$cert" | jq -r '.secretKey')

      DEST="$CERT_DIR/${NAME}.pem"
      echo "[sync-certs] Fetching $NAME from $SECRET:$KEY"
      if kubectl get secret "$SECRET" -n "$CERT_NAMESPACE" -o "jsonpath={.data.${KEY}}" 2>/dev/null | base64 -d > "$DEST"; then
        cat "$DEST" >> "$CERT_DIR/chain.pem"
        echo "" >> "$CERT_DIR/chain.pem"
      else
        echo "[sync-certs] Failed to fetch $NAME"
      fi
    done
  else
    echo "[sync-certs] WARNING: Kubernetes API not reachable, skipping cert sync."
    SKIP=true
  fi

  if [ -f "/usr/share/nginx/html/scripts/install.mobileconfig.tmpl" ] && ! $SKIP; then
    echo "[sync-certs] Regenerating mobileconfig with new cert..."
    export CA_CERT_BASE64="$(base64 -w 0 "$CERT_DIR/root.pem")"
    envsubst '${PORTAL_DOMAIN} ${CA_CERT_BASE64}' < /usr/share/nginx/html/scripts/install.mobileconfig.tmpl > /usr/share/nginx/html/scripts/install.mobileconfig
  fi

  echo "[sync-certs] Sleeping ${SYNC_INTERVAL_SECONDS} seconds..."
  sleep "$SYNC_INTERVAL_SECONDS"
done
