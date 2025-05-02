---
title: "Certificates UI"
permalink: index.html
---

## Certificates UI

Provide a UI for clients to install a self-signed certificate for a Kubernetes Cluster.

> **Current Version: 1.1.0**

### Install (helm)

Add repository to helm.

```shell
helm repo add certs-ui https://gjrtimmer.github.io/certs-ui
helm repo update
```

Install Certificates UI

```shell
helm install certs-ui certs-ui/certs-ui -n default
```

### Install (helmfile)

Install by using helmfile. (GitOps)

```yaml
repositories:
  - name: certs-ui
    url: https://gjrtimmer.github.io/certs-ui

releases:
- name: certs-ui
  namespace: certs-ui
  chart: certs-ui/certs-ui
  version: 1.1.0
  installed: true
  values:
    - values.yaml
```

#### values.yaml

When setting up the `Ingress` or `IngressRoute` (Traefik) ensure that you are serving this from either a `LetsEncrypt` or when using an internal self-signed certificate that the entrypoint is `http`.

```yaml
options:
  portalScheme: https
  portalDomain: certs.k3s
  certSecretName: internal-ca
  certSecretKey: ca.crt
  certNamespace: cert-manager
  syncIntervalSeconds: 300
```

##### Ingress

```yaml
ingress:
  enabled: true
  traefik:
    enabled: false
  className: ""
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: certs.k3s
      paths:
        - path: /
          pathType: ImplementationSpecific

options:
  portalScheme: https
  portalDomain: certs.k3s
  certSecretName: internal-ca
  certSecretKey: ca.crt
  certNamespace: cert-manager
  syncIntervalSeconds: 300
```

##### Traefik IngressRoute

```yaml
ingress:
  enabled: true
  traefik:
    enabled: true
    priority: 2000 # set priority to override https redirect
    entryPoints:
      - http
  className: traefik-internal
  annotations:
    cert-manager.io/ignore: "true"
  hosts:
    - host: certs.k3s
```
