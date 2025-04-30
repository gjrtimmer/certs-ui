#!/usr/bin/env bash
# shellcheck shell=bash disable=SC2016,SC2155
set -e

# Ensure PORTAL_DOMAIN is set
export PORTAL_DOMAIN="${PORTAL_DOMAIN:-certs.k3s}"

# Create certs directory if it doesn't exist
mkdir -p /usr/share/nginx/html/certs

# Start cert sync in background
echo "Starting background cert sync..."
/usr/bin/sync-certs.sh &

# Wait for initial certificate to be available
echo "Waiting for initial CA certificate to be available..."
until [ -s /usr/share/nginx/html/certs/ca-root.pem ]; do
  echo "Waiting for ca-root.pem..."
  sleep 2
done

echo "CA certificate available."

# Clean up old generated scripts and mobileconfig
find /usr/share/nginx/html/scripts/ -type f ! -name "*.tmpl" -delete

# Process .tmpl scripts (.sh, .ps1)
for template in /usr/share/nginx/html/scripts/*.tmpl; do
  [ -e "$template" ] || continue
  output="/usr/share/nginx/html/scripts/$(basename "$template" .tmpl)"
  echo "Generating script from template: $(basename "$output")"
  envsubst '${PORTAL_DOMAIN}' < "$template" > "$output"
  chmod +x "$output"
done

# Handle mobileconfig separately
if [ -f /usr/share/nginx/html/certs/ca-root.pem ] && [ -f /usr/share/nginx/html/scripts/install.mobileconfig.tmpl ]; then
  echo "Generating mobileconfig..."
  export CA_CERT_BASE64="$(base64 -w 0 /usr/share/nginx/html/certs/ca-root.pem)"
  envsubst '${PORTAL_DOMAIN} ${CA_CERT_BASE64}' < /usr/share/nginx/html/scripts/install.mobileconfig.tmpl > /usr/share/nginx/html/scripts/install.mobileconfig
fi

# Start Nginx
echo "Starting Nginx server..."
exec nginx -g "daemon off;"
