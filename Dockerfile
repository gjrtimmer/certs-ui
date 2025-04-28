FROM nginx:alpine

# Install envsubst (part of gettext)
# hadolint ignore=DL3018
RUN apk add --no-cache gettext

# Set up working directories
WORKDIR /usr/share/nginx/html

# Copy
COPY rootfs/ /

RUN chmod +x /entrypoint.sh

# Expose HTTP port
EXPOSE 80

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
