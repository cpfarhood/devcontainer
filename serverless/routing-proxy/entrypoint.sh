#!/bin/sh

# Set default values for environment variables
DEVCONTAINER_SERVICE_URL=${DEVCONTAINER_SERVICE_URL:-"devcontainer-serverless.devcontainers.svc.cluster.local"}

# Create temp directories
mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp

# Substitute environment variables in nginx config
envsubst '$DEVCONTAINER_SERVICE_URL' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "Starting routing proxy..."
echo "Routing to: $DEVCONTAINER_SERVICE_URL"

# Start nginx
exec "$@"