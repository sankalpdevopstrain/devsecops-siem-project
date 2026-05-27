# 🛡 DevSecOps SIEM Platform

> A cloud-native DevSecOps platform built from scratch — integrating CI/CD automation, container orchestration, infrastructure as code, and real-time security monitoring into a single production-style system.

Built independently after completing a DevOps training programme, extending the course curriculum with Docker, Kubernetes, Terraform, AWS EC2, and a custom-built SIEM dashboard.

---

## 📸 Live Demo — CI/CD Pipeline in Action

![DevSecOps Pipeline Demo](docs/DevSecOps.gif)

*A git push automatically triggers the full Jenkins pipeline — build, push to DockerHub, deploy to Kubernetes — with zero manual intervention.*

---

## 🏗 Architecture

```
Developer Workstation
        │
        ▼
   GitHub Repository
        │  webhook on every push
        ▼
   ngrok Tunnel
        │
        ▼
   Jenkins CI/CD (Docker container)
        │
        ├── Job 1: Build Docker Image
        ├── Job 2: Push to DockerHub
        └── Job 3: Deploy to Kubernetes
                         │
                         ▼
              Kubernetes Cluster
              (2 replicas, self-healing)
                         │
                         ▼
              SIEM Dashboard (port 3000)
                         ▲
                         │
              AWS EC2 Instance
              provisioned via Terraform
              ships real system logs
```

---

## 🚀 Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Source Control | GitHub | Version control + webhook triggers |
| CI/CD | Jenkins | Automated build, push, deploy pipeline |
| Containerisation | Docker | Application packaging + DockerHub registry |
| Orchestration | Kubernetes | Pod management, scaling, self-healing |
| Infrastructure as Code | Terraform | EC2 provisioning — no manual AWS console |
| Cloud Compute | AWS EC2 | Cloud instance shipping real logs to SIEM |
| Tunnelling | ngrok | Exposes local Jenkins via public HTTPS URL |
| Security Monitoring | Custom Node.js SIEM | Real-time event ingestion + alert dashboard |

---

## 📂 Project Structure

```
devsecops-siem-project/
│
├── app/                        # SIEM dashboard application
│   ├── app.js                  # Express server — REST API + dashboard UI
│   ├── Dockerfile              # Container definition
│   └── package.json
│
├── ec2/                        # AWS EC2 scripts
│   ├── ec2-activity.sh         # Ships real system activity to SIEM
│   └── ec2-alerts.sh           # Injects simulated alert events
│
├── jenkins/                    # CI/CD pipeline
│   └── Jenkinsfile             # 3-job pipeline definition
│
├── k8s/                        # Kubernetes manifests
│   ├── deployment.yaml         # 2-replica deployment
│   ├── service.yaml            # NodePort service
│   └── ingress.yaml            # Ingress configuration
│
├── scripts/                    # Platform automation
│   ├── start-platform.sh       # Single-command startup
│   ├── stop-platform.sh        # Clean shutdown
│   └── inject-demo-logs.sh     # Demo log injection
│
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # VPC, subnet, security group, EC2, key pair
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # EC2 IP, DNS, SSH command
│   └── user_data/
│       └── bootstrap.sh        # EC2 auto-bootstrap script
│
└── docs/                       # Full documentation
```

---

## ⚡ Quick Start

### Prerequisites

- Docker Desktop with Kubernetes enabled
- Git Bash (Windows) or Terminal (Mac/Linux)
- ngrok free account
- AWS free tier account
- Terraform v1.0+

### Start the platform

```bash
git clone https://github.com/sankalpdevopstrain/devsecops-siem-project.git
cd devsecops-siem-project
./scripts/start-platform.sh
```

### Access the platform

| Service | URL |
|---|---|
| Jenkins | http://localhost:8080 |
| SIEM Dashboard | http://localhost:8081 |
| ngrok Web UI | http://127.0.0.1:4040 |

### Inject demo logs

```bash
./scripts/inject-demo-logs.sh
```

### Stop the platform

```bash
./scripts/stop-platform.sh
```

---

## 🔄 CI/CD Pipeline

Every `git push` automatically triggers the full pipeline via GitHub webhook:

```
git push origin main
      │
      ▼
GitHub Webhook → ngrok → Jenkins
      │
      ├── Job 1 — CI Build
      │         docker build -t devsecops-app:latest .
      │
      ├── Job 2 — CD Push
      │         docker push sankalpdevops/devsecops-app:latest
      │
      └── Job 3 — CD Deploy
                kubectl apply -f k8s/
                kubectl rollout restart deployment devsecops-app
```

---

## 🛡 SIEM Dashboard

A custom-built security monitoring dashboard that ingests events from multiple sources and classifies them by severity.

### Severity Classification

| Event | Severity | Display |
|---|---|---|
| `failed_login` | HIGH | 🟥 Red border |
| `level: error` | CRITICAL | 🔴 Red background |
| `login_success` | LOW | 🟩 Green border |
| `health_check` | LOW | 🟩 Green border |

### Log Sources

- **Jenkins** — build and deployment events
- **GitHub** — webhook push events
- **Kubernetes** — deployment status events
- **AWS EC2** — real system logs via ngrok tunnel
- **Manual** — operator events via `log` helper on EC2

### API Endpoints

```
POST /logs            Ingest a log event
GET  /logs            Retrieve all logs (JSON)
GET  /health          Health check endpoint
GET  /                Live dashboard UI
POST /github-webhook  GitHub webhook receiver
```

---

## ☁ AWS EC2 + Terraform

The EC2 instance is provisioned entirely via Terraform — no manual clicking in the AWS console.

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

Provisions: VPC, public subnet, internet gateway, security group, SSH key pair, t3.micro EC2 (Ubuntu 26.04 LTS), and a bootstrap script that auto-installs Docker and Node.js.

### Shipping real EC2 logs to the SIEM

```bash
ssh -i ~/.ssh/devsecops-key.pem ubuntu@<EC2_PUBLIC_IP>

# Built-in log helper — ships directly to SIEM dashboard
log "System update completed"
sudo apt-get update && log "apt-get update ran successfully"
```

### Tear down when finished

```bash
terraform destroy
```

---

## 📊 Kubernetes

```bash
kubectl get pods          # Check running pods (2 replicas)
kubectl get deployments   # Check deployment status
kubectl get svc           # Check service exposure
```

---

## 🔮 Roadmap

- [ ] Persistent log storage — replace in-memory with MongoDB
- [ ] Auto-refresh SIEM dashboard
- [ ] Jenkins deployed to EC2 via Terraform
- [ ] ELK stack integration
- [ ] Alert notifications via Slack or email
- [ ] GitHub Actions as alternative CI/CD layer

---

## 📖 Documentation

| Doc | Description |
|---|---|
| [Project Overview](docs/01-project-overview.md) | Goals, business problem, skills demonstrated |
| [Architecture](docs/02-architecture.md) | System design and component decisions |
| [Jenkins Pipeline](docs/03-jenkins-pipeline.md) | CI/CD pipeline setup and job flow |
| [Docker Build](docs/04-docker-build.md) | Containerisation process |
| [Kubernetes Deployment](docs/05-kubernetes-deployment.md) | Orchestration setup |
| [SIEM Dashboard](docs/06-siem-dashboard.md) | Security monitoring layer |
| [Webhook Integration](docs/07-webhook-integration.md) | GitHub to Jenkins automation |
| [Terraform + EC2](docs/08-terraform-ec2.md) | Infrastructure as Code and cloud logging |
| [Final Demo](docs/09-final-demo.md) | End-to-end platform walkthrough |

---

## 👤 Author

**Sankalp Hiregoudar**
GitHub: [@sankalpdevopstrain](https://github.com/sankalpdevopstrain)

*Built as a self-directed portfolio project after completing a DevOps training programme — demonstrating practical DevSecOps engineering beyond the course curriculum.*

---

## 📄 Licence

MIT — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.
