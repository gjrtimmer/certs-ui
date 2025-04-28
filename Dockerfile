FROM nginx:alpine

# Install envsubst (part of gettext)
# hadolint ignore=DL3018
RUN apk add --no-cache gettext

# Set up working directories
WORKDIR /usr/share/nginx/html

# Copy static web content
COPY html/ /usr/share/nginx/html/
COPY scripts/ /usr/share/nginx/html/scripts/
COPY config/nginx.conf /etc/nginx/nginx.conf

# Ensure certs directory exists
RUN mkdir -p /usr/share/nginx/html/certs

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose HTTP port
EXPOSE 80

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
