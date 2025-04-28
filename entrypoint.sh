#!/bin/sh
set -e

# Create certs directory if it doesn't exist
mkdir -p /usr/share/nginx/html/certs

# Start Nginx
echo "Starting Nginx server..."
exec nginx -g "daemon off;"
