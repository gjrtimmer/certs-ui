#!/bin/bash
set -e

NAMESPACE="${NAMESPACE:-cert-manager}"
CERT_SECRET_NAME="${CERT_SECRET_NAME:-internal-ca}"   # Update this if your cert secret has a different name
ROOT_CERT="${ROOT_CERT:-./certs/ca-root.pem}"

echo "Starting certificate sync..."

mkdir -p ./certs

echo "Fetching certificate from Kubernetes..."
kubectl get secret "${CERT_SECRET_NAME}" -n "${NAMESPACE}" -o jsonpath='{.data.tls\.crt}' | base64 -d > "$ROOT_CERT"

echo "Certificate synced successfully to $ROOT_CERT"
