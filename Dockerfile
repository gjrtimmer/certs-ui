FROM nginx:alpine

ARG TARGETARCH

# Install envsubst (part of gettext)
# hadolint ignore=DL3018
RUN apk add --no-cache gettext kubectl wget ca-certificates

# Install kubectl (needed for sync-certs)
RUN wget -qO /usr/local/bin/kubectl https://dl.k8s.io/release/v1.28.2/bin/linux/${TARGETARCH}/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Set up working directories
WORKDIR /usr/share/nginx/html

# Copy
COPY rootfs/ /

RUN chmod +x /entrypoint.sh && \
    chmod +x /usr/share/nginx/html/scripts/*.sh

# Expose HTTP port
EXPOSE 80

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
