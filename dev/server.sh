#!/usr/bin/env bash
set -e

PORT=8080
WEBROOT="."
CERT_SYNC_SCRIPT="./sync-certs.sh"
ROOT_CERT="${ROOT_CERT:-./certs/ca-root.pem}"

echo "Starting development server for certs.k3s project..."
echo ""

# Step 0: Set up Python venv
if [ ! -d ".venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv .venv
fi

echo "Activating virtual environment..."
# shellcheck disable=SC1091
source .venv/bin/activate
echo "Using root certificate: $ROOT_CERT"

# Step 1: Sync certificates from Kubernetes (if sync script exists)
if [ -f "$CERT_SYNC_SCRIPT" ]; then
    echo "Syncing certificates from Kubernetes..."
    bash "$CERT_SYNC_SCRIPT" || echo "Warning: sync-certs.sh failed (maybe no Kubernetes access)"
else
    echo "No sync-certs.sh found. Skipping cert sync."
fi

# Step 2: Start local webserver
echo ""
echo "Serving files from '$WEBROOT' on http://localhost:$PORT/"
echo "Tip: Open your browser and navigate to http://localhost:$PORT/html/index.html"
echo ""

# Start the Python 3 simple HTTP server
python3 -m http.server "$PORT" --directory "$WEBROOT"
