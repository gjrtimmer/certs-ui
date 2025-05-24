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
    while read -r cert; do
      NAME=$(echo "$cert" | jq -r '.name')
      SECRET=$(echo "$cert" | jq -r '.secretName')
      KEY=$(echo "$cert" | jq -r '.secretKey')
      NAMESPACE=$(echo "$cert" | jq -r '.namespace // env.CERT_NAMESPACE')

      DEST="$CERT_DIR/${NAME}.pem"
      echo "[sync-certs] Fetching $NAME from $SECRET:$KEY"
      BASE64_DATA=$(kubectl get secret "$SECRET" -n "$NAMESPACE" -o "jsonpath={.data.${KEY}}" 2>&1)
      if echo "$BASE64_DATA" | grep -q "Error"; then
        echo "[sync-certs] ERROR: $BASE64_DATA"
        continue
      fi
      if [[ -n "$BASE64_DATA" ]]; then
        echo "$BASE64_DATA" | base64 -d > "$DEST" || echo "[sync-certs] base64 decoding failed for $NAME"
        echo "[sync-certs] Wrote $(wc -c < "$DEST") bytes to $DEST"
        cat "$DEST" >> "$CERT_DIR/chain.pem"
        echo "" >> "$CERT_DIR/chain.pem"
      else
        echo "[sync-certs] No data found for $NAME from $SECRET in $NAMESPACE"
      fi
    done < <(echo "$CERT_LIST_JSON" | jq -c '.[]')
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
