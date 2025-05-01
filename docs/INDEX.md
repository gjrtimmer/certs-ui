---
title: "Certificates UI"
permalink: index.html
---

## Certificates UI

Provide a UI for clients to install a self-signed certificate for a Kubernetes Cluster.

> **Current Version: 0.1.0**

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
  version: 0.1.0
  installed: true
  values:
    - values.yaml
```

#### values.yaml

```yaml
options:
  portalDomain: certs.k3s
  certSecretName: internal-ca
  certSecretKey: ca.crt
  certNamespace: cert-manager
  syncIntervalSeconds: 300
```
