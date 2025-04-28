---
title: "Certificates UI"
permalink: index.html
---

## Certificates UI

Provide a UI for clients to install a self-signed certificate for a Kubernetes Cluster.

### Install

Add repository to helm.

```shell
helm repo add certs-ui https://gjrtimmer.github.io/certs-ui
helm repo update
```

Install Certificates UI

```shell
helm install certs-ui certs-ui/certs-ui -n default
```
