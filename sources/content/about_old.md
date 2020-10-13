---
title: "[ about : k3lab.gq ]"
date: 2020-01-15T14:54:51+01:00
showthedate: false
draft: true
---

Empowering devs to easily bootstrap a Kubernetes DevOps/GitOps complete environment and pipelines using a minimal (and free of charge) k3s cluster.


The main idea is to have an easilly deployable (and pseudo production-ready) setup that can be used for dev/test, or as a homelab for tool testing and learning purposes.

Documentation will be extensive by design to make it easy to follow this steps even if you're not familiar with k3/8s internals.
In any case, the main goal is to go from I-dont-even-have-a-spare-vm to a complete Dev/Git-Ops Environment in ~10m

Some tools that we'll be running in our k3s cluster:
- Jenkins
- ArgoCD, for k3s management
- Harbor, to host our own Registry 
- Prometheus+Grafana7
- MariaDB Server
- GitLab
- OpenFAAS Playground
- Demo APIs and web services in order to load/perf testing
- Development Environment #1: Embed VSCode + shell
- Development Environment #2: Embed Theia + shell
- Rancher, admin board (although 100% of the documentation will be covered using the CLI).  
  alt: Portainer, admin board
- MinIO, blob storage (AWS S3 alike) 

Extras:
- Longhorn, persistent storage.
- Helm2 + Upgrade to Helm3.
- LetsEncrypt cert-manager's magic.
