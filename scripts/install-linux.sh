#!/bin/bash
set -e

echo "Downloading internal CA certificate..."
curl -fsSL -o /tmp/ca-root.pem https://certs.k3s/certs/ca-root.pem

echo "Installing certificate..."
sudo cp /tmp/ca-root.pem /usr/local/share/ca-certificates/internal-ca.crt
sudo update-ca-certificates

echo "Internal CA installed successfully."
    