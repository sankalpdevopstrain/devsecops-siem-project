# 🚀 Final System Demo — DevSecOps SIEM Platform

- [🚀 Final System Demo — DevSecOps SIEM Platform](#-final-system-demo--devsecops-siem-platform)
  - [🎯 Demo Objective](#-demo-objective)
  - [🧠 End-to-End System Flow](#-end-to-end-system-flow)
  - [🏗 Full Architecture (Live System Behaviour)](#-full-architecture-live-system-behaviour)
  - [🔁 Live Demo Walkthrough (What Happens in Real Time)](#-live-demo-walkthrough-what-happens-in-real-time)
    - [Step 1 — Code Push Trigger](#step-1--code-push-trigger)
    - [Step 2 — Jenkins CI/CD Execution](#step-2--jenkins-cicd-execution)
    - [Step 3 — Docker Container Build](#step-3--docker-container-build)
    - [Step 4 — Kubernetes Deployment](#step-4--kubernetes-deployment)
    - [Step 5 — SIEM Log Generation](#step-5--siem-log-generation)
    - [Step 6 — SIEM Dashboard Visualisation](#step-6--siem-dashboard-visualisation)
  - [🔐 Security Highlights](#-security-highlights)
  - [🧠 Key Technical Skills Demonstrated](#-key-technical-skills-demonstrated)
  - [🖥 SIEM Dashboard — Initial System State](#-siem-dashboard--initial-system-state)
  - [🚨 SIEM Dashboard — Live Event Detection](#-siem-dashboard--live-event-detection)
  - [🎨 Alert Visualisation](#-alert-visualisation)
  - [⚙ CI/CD Pipeline Execution](#-cicd-pipeline-execution)
    - [Pipeline Overview](#pipeline-overview)
    - [Job 1 — CI Build](#job-1--ci-build)
    - [Job 2 — Container Build \& Release](#job-2--container-build--release)
    - [Job 3 — Cluster Deployment](#job-3--cluster-deployment)
    - [Full Pipeline Execution](#full-pipeline-execution)
  - [🔗 GitHub Webhook Automation](#-github-webhook-automation)
    - [Live Webhook Demonstration](#live-webhook-demonstration)
  - [Final End-to-End Platform Demonstration:](#final-end-to-end-platform-demonstration)

---

## 🎯 Demo Objective

This final demo demonstrates the full end-to-end workflow of the DevSecOps SIEM platform, showcasing:

- Continuous Integration & Deployment (CI/CD)
- Containerised application delivery
- Kubernetes orchestration
- Event-driven automation using GitHub Webhooks
- Real-time security monitoring via SIEM dashboard

The purpose of this demo is to simulate a **real-world production DevSecOps pipeline with integrated security visibility**.

---

## 🧠 End-to-End System Flow

The system operates as a fully automated pipeline:

1. Developer pushes code to GitHub  
2. GitHub triggers a webhook event  
3. Jenkins automatically starts CI/CD pipeline  
4. Application is built and containerised using Docker  
5. Kubernetes deploys the application  
6. Application generates runtime logs  
7. SIEM dashboard processes and displays security events  

---

## 🏗 Full Architecture (Live System Behaviour)

This project integrates four key layers:

- **Source Control Layer (GitHub)** → Code and webhook trigger
- **CI/CD Layer (Jenkins)** → Automation engine
- **Container Layer (Docker)** → Application packaging
- **Orchestration Layer (Kubernetes)** → Deployment runtime
- **Security Layer (SIEM Dashboard)** → Log analysis and monitoring

---

## 🔁 Live Demo Walkthrough (What Happens in Real Time)

### Step 1 — Code Push Trigger
A developer pushes a change to the GitHub repository:

```bash
git add .
git commit -m "final demo trigger"
git push origin main
```
This triggers a GitHub webhook event.

### Step 2 — Jenkins CI/CD Execution

Jenkins automatically receives the webhook and starts the pipeline:

* Pulls latest code from GitHub
* Builds Node.js application
* Runs Docker build process
* Pushes deployment configuration

### Step 3 — Docker Container Build

The application is packaged into a container image:

* Application runtime bundled
* Dependencies installed
* Image created for deployment consistency

### Step 4 — Kubernetes Deployment

The container is deployed into a Kubernetes cluster:

* Pods are created automatically
* Service exposes the application
* Application becomes accessible via browser

### Step 5 — SIEM Log Generation

While the system runs, multiple logs are generated:

* Failed login attempts
* API requests
* Jenkins build logs
* Kubernetes deployment events

### Step 6 — SIEM Dashboard Visualisation

All logs are displayed in real time inside the dashboard:

* Total event count
* Alert count
* Severity classification (LOW / MEDIUM / HIGH)
* Recent security events
---
## 🔐 Security Highlights

This project demonstrates practical DevSecOps security principles:

* Event-driven automation reduces manual intervention
* Centralised log monitoring improves visibility
* CI/CD pipeline provides traceable deployment history
* Kubernetes ensures workload isolation and resilience
* SIEM layer provides real-time threat detection simulation
---
## 🧠 Key Technical Skills Demonstrated
* CI/CD pipeline automation (Jenkins)
* Containerisation (Docker)
* Kubernetes orchestration
* Webhook-based event-driven architecture
* Log ingestion and SIEM simulation
* Full-stack DevSecOps implementation

## 🖥 SIEM Dashboard — Initial System State

The dashboard first loads in a monitoring-ready state before any security events are generated.

This confirms:

- Application successfully deployed
- Dashboard UI accessible
- Log engine initialised
- Monitoring services active

![Mini SIEM Dashboard](image-7.png)

---
## 🚨 SIEM Dashboard — Live Event Detection

After generating test security events, the dashboard begins processing and displaying alerts in real time.

This demonstrates:

- Successful log ingestion
- Real-time event processing
- Alert detection and severity classification
- Operational visibility across the platform

![Events with alerts](image-8.png)

---
## 🎨 Alert Visualisation

The dashboard uses colour-based event classification to improve situational awareness:

- 🟥 **Red** → Security alert or suspicious activity detected
- 🟩 **Green** → Normal or safe operational event
---

## ⚙ CI/CD Pipeline Execution

Following a source code commit, Jenkins automatically executes the full deployment pipeline.

This validates:

* Source code retrieval from GitHub
* Application dependency validation
* Container build preparation
* Automated deployment workflow

### Pipeline Overview

The pipeline is composed of three linked automation jobs:

### Job 1 — CI Build

This stage validates the application source code and confirms the application is build-ready.

Validated activities:

* Repository checkout
* Dependency installation
* Application startup verification

![DevSecOps CI Build](image-10.png)

### Job 2 — Container Build & Release

This stage builds the application container using Docker and prepares the deployment artifact.

Validated activities:

* Container image build
* Image tagging
* Deployment artifact preparation

![DevSecOps CD Push](image-11.png)

### Job 3 — Cluster Deployment

This stage deploys the application into the Kubernetes cluster.

Validated activities:

* Deployment manifest execution
* Service update
* Pod health verification

![DevSecOps CD Deploy](image-12.png)

### Full Pipeline Execution 
The complete pipeline executes automatically from build to deployment.

This confirms:

* End-to-end CI/CD automation
* Zero manual deployment intervention
* Production-style deployment workflow
* Operational traceability

![All 3 jobs sucessfully running](image-13.png)

---
## 🔗 GitHub Webhook Automation

The platform uses GitHub webhooks to automatically trigger the Jenkins CI/CD pipeline whenever new code is pushed to the repository.

This validates:

* Real-time event-driven automation
* Automatic Jenkins pipeline execution
* Zero manual deployment intervention
* Full CI/CD traceability

### Live Webhook Demonstration

The following demonstration shows:

1. Source code pushed to GitHub
2. GitHub webhook event generated
3. Jenkins automatically triggered
4. CI Build → Container Build → Kubernetes Deployment completed successfully

**Jenkins Console Validation:**

> Started by GitHub push by sankalpdevopstrain

That “Started by GitHub push...” line is powerful proof.

---
## Final End-to-End Platform Demonstration:
![DevSecOps](DevSecOps.gif)