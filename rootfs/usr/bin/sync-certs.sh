#!/bin/bash
# shellcheck shell=bash disable=SC2016,SC2155
set -e

CERT_NAMESPACE="${CERT_NAMESPACE:-cert-manager}"
SYNC_INTERVAL_SECONDS="${SYNC_INTERVAL_SECONDS:-300}"
CERT_LIST_JSON="${CERT_LIST_JSON:-[]}"

# Validate CERT_LIST_JSON
if [[ -z "$CERT_LIST_JSON" || "$CERT_LIST_JSON" == "[]" ]]; then
  echo "[sync-certs] CERT_LIST_JSON is empty. Exiting."
  exit 1
fi

CERT_DIR="/usr/share/nginx/html/certs"

if [[ ! -d "$CERT_DIR" ]]; then
  echo "[sync-certs] Creating certs directory at $CERT_DIR"
  mkdir -p "$CERT_DIR"
fi

if [[ ! -d "/usr/share/nginx/html/js" ]]; then
  echo "[sync-certs] Creating scripts directory at /usr/share/nginx/html/js"
  mkdir -p /usr/share/nginx/html/js
fi

while true; do
  SKIP=false
  echo "[sync-certs] Syncing all certificates from Kubernetes..."

  if kubectl get --raw=/healthz > /dev/null 2>&1; then
    echo "[sync-certs] Kubernetes API is reachable, fetching certs..."
    TMP_CHAIN="$CERT_DIR/tmp_chain.pem"
    TMP_FP="$CERT_DIR/tmp_chain.pem.fingerprints"
    : > "$TMP_CHAIN"
    : > "$TMP_FP"
    while read -r cert; do
      NAME=$(echo "$cert" | jq -r '.name')
      SECRET=$(echo "$cert" | jq -r '.secretName')
      KEY=$(echo "$cert" | jq -r '.secretKey')
      NAMESPACE=$(echo "$cert" | jq -r '.namespace // env.CERT_NAMESPACE')

      DEST="$CERT_DIR/${NAME}.pem"
      echo "[sync-certs] Fetching $NAME from $SECRET:$KEY in $NAMESPACE"
      BASE64_DATA=$(kubectl get secret "$SECRET" -n "$NAMESPACE" -o json | jq -r ".data[\"$KEY\"]")
      if [[ -z "$BASE64_DATA" ]]; then
        echo "[sync-certs] No data found for $NAME from $SECRET in $NAMESPACE"
        continue
      fi

      echo "$BASE64_DATA" | base64 -d > "$DEST" || { echo "[sync-certs] base64 decoding failed for $NAME"; continue; }
      echo >> "$DEST"
    done < <(echo "$CERT_LIST_JSON" | jq -c '.[]')

    cat "$CERT_DIR"/*.pem > "$CERT_DIR/tmp_chain.pem.cat" && \
    mv "$CERT_DIR/tmp_chain.pem.cat" "$CERT_DIR/tmp_chain.pem" && \

    csplit -f /tmp/cert "$CERT_DIR/tmp_chain.pem" '/-----BEGIN CERTIFICATE-----/' '{*}' >/dev/null 2>&1

    # Reset chain and fingerprints file
    : > "$TMP_CHAIN"
    : > "$TMP_FP"

    for f in /tmp/cert*; do
      [[ "$f" == "/tmp/cert00" ]] && continue
      if openssl x509 -in "$f" -noout >/dev/null 2>&1; then
        sum=$(openssl x509 -in "$f" -noout -fingerprint -sha256 | cut -d= -f2)
        if ! grep -q "$sum" "$TMP_FP"; then
          cat "$f" >> "$TMP_CHAIN"
          echo "$sum" >> "$TMP_FP"
        fi
      else
        echo "[sync-certs] Skipping invalid certificate chunk: $f"
      fi
    done

    mv "$TMP_CHAIN" "$CERT_DIR/chain.pem"
    mv "$TMP_FP" "$CERT_DIR/chain.pem.fingerprints"

    rm -f /tmp/cert*
  else
    echo "[sync-certs] WARNING: Kubernetes API not reachable, skipping cert sync."
    SKIP=true
  fi

  if [ -f "/usr/share/nginx/html/scripts/install.mobileconfig.tmpl" ] && ! $SKIP; then
    echo "[sync-certs] Regenerating mobileconfig with new cert..."
    export CA_CERT_BASE64="$(base64 -w 0 "$CERT_DIR/root.pem")"
    envsubst '${PORTAL_DOMAIN} ${CA_CERT_BASE64}' < /usr/share/nginx/html/scripts/install.mobileconfig.tmpl > /usr/share/nginx/html/scripts/install.mobileconfig
  fi

  # Inject certificate list for frontend
  echo "Injecting certificate list for frontend..."
  CERT_LIST=$(ls /usr/share/nginx/html/certs/*.pem | xargs -n1 basename | tr '\n' ',' | sed 's/,$//')
  echo "<script>window.CERT_LIST = \"$CERT_LIST\";</script>" > /usr/share/nginx/html/js/cert-list.js

  echo "[sync-certs] Sleeping ${SYNC_INTERVAL_SECONDS} seconds..."
  sleep "$SYNC_INTERVAL_SECONDS"
done
