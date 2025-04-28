#!/bin/bash
set -e

echo "Downloading internal CA certificate..."
curl -fsSL -o ~/Downloads/internal-ca.pem https://certs.k3s/certs/ca-root.pem

echo "Installing certificate into system keychain..."
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ~/Downloads/internal-ca.pem


echo "Internal CA installed successfully."
echo "Cleaning up downloaded certificate..."
rm -f ~/Downloads/internal-ca.pem
