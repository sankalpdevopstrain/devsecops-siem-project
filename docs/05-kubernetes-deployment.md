# ☸ Kubernetes Deployment

---

## Overview

Kubernetes manages the SIEM application in a production-style container environment. It handles scheduling, networking, self-healing, and scaling — removing the need for manual container management.

---

## Architecture Diagram

![Kubernetes Architecture](image-4.png)

---

## Why Kubernetes

Running a single Docker container works for development but lacks resilience. Kubernetes adds:

- **Self-healing** — failed pods are automatically restarted
- **Scaling** — replicas handle increased load
- **Service discovery** — stable internal networking
- **Declarative config** — infrastructure defined as code in YAML

---

## Cluster Setup

The cluster runs via Docker Desktop's built-in Kubernetes on the local machine. This reflects a real Kubernetes environment without requiring cloud infrastructure.

```bash
kubectl config current-context
# docker-desktop
```

---

## Resources Deployed

### Deployment

Maintains 2 running replicas of the SIEM application at all times.

```yaml
replicas: 2
image: sankalpdevops/devsecops-app:latest
containerPort: 3000
```

```bash
kubectl get deployments
# NAME            READY   UP-TO-DATE   AVAILABLE   AGE
# devsecops-app   2/2     2            2           15d
```

### Pods

Each pod runs one instance of the SIEM container.

```bash
kubectl get pods
# devsecops-app-7d58c886cf-ffxsg   1/1   Running   3   14d
# devsecops-app-7d58c886cf-vxsrm   1/1   Running   3   14d
```

### Service

A NodePort service routes external traffic to the pods.

```bash
kubectl get svc
# devsecops-app-service   NodePort   10.96.121.234   80:30564/TCP   15d
```

### Port Forward

The SIEM dashboard is accessed locally via port-forward:

```bash
kubectl port-forward svc/devsecops-app-service 8081:80
# Forwarding from 127.0.0.1:8081 -> 3000
```

This is automated inside `scripts/start-platform.sh`.

---

## Jenkins Deployment

Job 3 applies the manifests automatically after every successful build:

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

---

## Self-Healing Demonstration

The `RESTARTS` column in `kubectl get pods` shows Kubernetes has automatically recovered the pods multiple times since deployment — without any manual intervention.

```bash
kubectl get pods
# RESTARTS: 3 (after system restarts)
```

---

## Security Considerations

- Pods are isolated from the host — containers cannot directly access host resources
- The NodePort service only exposes port 30564 externally
- Port-forward is used for local access instead of exposing the cluster publicly
- Kubernetes deployment history provides full rollback capability
