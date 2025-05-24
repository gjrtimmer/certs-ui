#!/usr/bin/env bash
# shellcheck shell=bash disable=SC2016,SC2155
set -e

export PORTAL_SCHEME="${PORTAL_SCHEME:-https}"
export PORTAL_DOMAIN="${PORTAL_DOMAIN:-certs.k3s}"

# Create certs directory if it doesn't exist
mkdir -p /usr/share/nginx/html/certs

# Start cert sync in background
echo "Starting background cert sync..."
/usr/bin/sync-certs.sh &

# Wait for chain.pem certificate file
echo "Waiting for chain.pem certificate file..."
until [ -s /usr/share/nginx/html/certs/chain.pem ]; do
  echo "Waiting for chain.pem..."
  sleep 2
done

echo "chain.pem certificate available."

# Clean up old generated scripts and mobileconfig
find /usr/share/nginx/html/scripts/ -type f ! -name "*.tmpl" -delete

# Process .tmpl scripts (.sh, .ps1)
for template in /usr/share/nginx/html/scripts/*.tmpl; do
  [ -e "$template" ] || continue
  output="/usr/share/nginx/html/scripts/$(basename "$template" .tmpl)"
  echo "Generating script from template: $(basename "$output")"
  envsubst '${PORTAL_SCHEME} ${PORTAL_DOMAIN}' < "$template" > "$output"
  chmod +x "$output"
done

# Handle mobileconfig separately
if [ -f /usr/share/nginx/html/certs/chain.pem ] && [ -f /usr/share/nginx/html/scripts/install.mobileconfig.tmpl ]; then
  echo "Generating mobileconfig..."
  export CA_CERT_BASE64="$(base64 -w 0 /usr/share/nginx/html/certs/chain.pem)"
  export CA_CERT_FILENAME="chain.pem"
  envsubst '${PORTAL_DOMAIN} ${CA_CERT_BASE64} ${CA_CERT_FILENAME}' < /usr/share/nginx/html/scripts/install.mobileconfig.tmpl > /usr/share/nginx/html/scripts/install.mobileconfig
fi


# Inject certificate list for frontend
echo "Injecting certificate list for frontend..."
CERT_LIST=$(ls /usr/share/nginx/html/certs/*.pem | xargs -n1 basename | tr '\n' ',' | sed 's/,$//')
echo "<script>window.CERT_LIST = \"$CERT_LIST\";</script>" > /usr/share/nginx/html/scripts/cert-list.js

# Start Nginx
echo "Starting Nginx server..."
exec nginx -g "daemon off;"
