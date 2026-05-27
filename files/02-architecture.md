# 🏗 System Architecture

---

## Architecture Goal

The platform was designed around five integrated layers, each with a clear responsibility. The goal was to build a system where security is embedded directly into the delivery pipeline — not bolted on afterwards.

---

## Architecture Diagram

![Component Architecture Diagram](image-1.png)

---

## Layer Breakdown

### 1. Source Control — GitHub

Every change starts here. A developer pushes code and GitHub automatically generates a webhook event containing the commit details, branch, and author.

**Security value:** Full change traceability. Every deployment is tied to a specific commit.

---

### 2. Tunnelling — ngrok

Because Jenkins runs locally, ngrok creates a secure public HTTPS tunnel so GitHub can deliver webhooks to it. The free plan provides a fixed subdomain, meaning the webhook URL never changes between restarts.

```
https://previous-stinky-maturity.ngrok-free.dev → localhost:8080
```

---

### 3. CI/CD — Jenkins

Jenkins runs as a Docker container and orchestrates three chained jobs:

| Job | Responsibility |
|---|---|
| devsecops-ci-build | Pull code, build Docker image |
| devsecops-cd-push | Tag and push image to DockerHub |
| devsecops-cd-deploy | Apply Kubernetes manifests |

Each job triggers the next automatically — zero manual intervention.

---

### 4. Containerisation — Docker

The SIEM application is packaged into a Docker image containing the Node.js runtime, application code, and all dependencies. This ensures identical behaviour across every environment.

The built image is stored in DockerHub under `sankalpdevops/devsecops-app:latest`.

---

### 5. Orchestration — Kubernetes

The application runs in a Kubernetes cluster with two replicas for resilience. If a pod fails, Kubernetes automatically restarts it — self-healing infrastructure with no manual intervention.

```bash
kubectl get pods        # 2/2 Running
kubectl get deployments # 2/2 Available
kubectl get svc         # NodePort exposed on :30564
```

---

### 6. Cloud Infrastructure — AWS EC2 + Terraform

An EC2 instance is provisioned entirely through Terraform. No manual steps in the AWS console. The instance runs Ubuntu 26.04 LTS on a t3.micro (free tier) inside a custom VPC.

On first boot, a `user_data` bootstrap script automatically installs Docker and Node.js, then starts a log shipper service.

---

### 7. Security Monitoring — Custom SIEM Dashboard

The SIEM dashboard is built with Node.js and Express. It exposes a REST API at `/logs` that accepts JSON events from any source. Events are classified by severity and displayed in a live browser dashboard.

Real EC2 system logs flow through the ngrok tunnel directly into the dashboard, providing genuine cloud telemetry alongside simulated alert events.

---

## Design Decisions

| Decision | Rationale |
|---|---|
| Jenkins over GitHub Actions | Full pipeline control, enterprise adoption, runs locally |
| Custom SIEM over existing tools | Demonstrates understanding of security principles, not just tool usage |
| Terraform for EC2 | Reproducible infrastructure — core DevSecOps practice |
| ngrok fixed subdomain | Persistent webhook URL without paid cloud hosting |
| 2 Kubernetes replicas | Demonstrates high availability thinking |

---

## Security Considerations

- All external access goes through ngrok HTTPS — no plain HTTP exposure
- EC2 security group restricts inbound ports to 22, 80, 443, 3000 only
- Terraform state files excluded from version control via `.gitignore`
- SSH key pair managed as a Terraform resource
- Jenkins credentials stored in Jenkins credential store (not hardcoded)
