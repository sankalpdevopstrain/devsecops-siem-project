# 🔗 GitHub Webhook Integration (Event-Driven CI/CD Trigger)
- [🔗 GitHub Webhook Integration (Event-Driven CI/CD Trigger)](#-github-webhook-integration-event-driven-cicd-trigger)
  - [🎯 Objective](#-objective)
  - [⚙️ Why Webhooks Were Used](#️-why-webhooks-were-used)
  - [🔁 High-Level Flow](#-high-level-flow)
  - [🏗 Architecture Diagram (Webhook Flow)](#-architecture-diagram-webhook-flow)
  - [📊 Explanation of Architecture Diagram](#-explanation-of-architecture-diagram)
  - [🔧 Implementation Steps](#-implementation-steps)
    - [Step 1 — Configure GitHub Webhook](#step-1--configure-github-webhook)
    - [Step 2 — Expose Jenkins (Local Testing)](#step-2--expose-jenkins-local-testing)
    - [Step 3 — Jenkins Configuration](#step-3--jenkins-configuration)
    - [Step 4 — Test Webhook Trigger](#step-4--test-webhook-trigger)
  - [🔐 Security Considerations](#-security-considerations)
  - [📡 Event Payload Example](#-event-payload-example)

---

## 🎯 Objective

The purpose of webhook integration in this project is to enable **automated CI/CD triggering** whenever changes are pushed to the GitHub repository.

This removes the need for manual Jenkins job execution and creates a fully event-driven DevSecOps pipeline.

---

## ⚙️ Why Webhooks Were Used

Traditional CI/CD systems rely on polling or manual triggers, which introduce delays.

Webhooks solve this by:

- Triggering Jenkins instantly on code changes
- Reducing deployment latency
- Enabling real-time automation
- Supporting event-driven architecture

---

## 🔁 High-Level Flow

1. Developer pushes code to GitHub
2. GitHub sends a webhook event
3. Jenkins receives the event
4. Jenkins pipeline is triggered automatically
5. CI/CD process begins (build → docker → deploy)

---

## 🏗 Architecture Diagram (Webhook Flow)

![Webhook Flow](image-6.png)

## 📊 Explanation of Architecture Diagram

The diagram illustrates an event-driven DevSecOps workflow where a code change directly triggers automated deployment and security monitoring.

The process begins when a developer pushes code to the GitHub repository. This action generates a webhook event containing metadata such as commit details, branch information, and author identity.

The webhook is sent to Jenkins, which acts as the CI/CD orchestration engine. Jenkins is responsible for executing the pipeline without manual intervention, ensuring consistency and repeatability across deployments.

Within the CI/CD pipeline, Jenkins performs the following key stages:

- Retrieves the latest source code from GitHub  
- Builds and validates the application  
- Creates a Docker container image  
- Deploys the application into a Kubernetes cluster  

Kubernetes then manages the runtime environment by scheduling pods, handling service exposure, and ensuring application availability and resilience.

In parallel, system and application logs are generated from multiple sources, including Jenkins execution, application runtime events, Kubernetes activity, and GitHub webhook triggers.

These logs are forwarded to the SIEM dashboard, where they are processed in real time. The system applies rule-based logic to classify events, detect anomalies such as failed logins or deployment errors, and visualise them as alerts.

This architecture demonstrates a fully automated DevSecOps pipeline with integrated security monitoring, enabling continuous delivery alongside real-time operational visibility.

## 🔧 Implementation Steps

### Step 1 — Configure GitHub Webhook

In the GitHub repository:

- Navigate to **Settings → Webhooks**
- Click **Add webhook**
- Configure the following:

| Field | Value |
|------|------|
| Payload URL | `http://<jenkins-url>/github-webhook/` |
| Content type | `application/json` |
| Events | Push events |

---

### Step 2 — Expose Jenkins (Local Testing)

If running locally, tools like **ngrok** were used:

```bash
ngrok http 8080
```

### Step 3 — Jenkins Configuration

In Jenkins:

* Enable GitHub hook trigger for GITScm polling
* Configure pipeline job with Git repository URL
* Ensure credentials are set if required

### Step 4 — Test Webhook Trigger

A test commit was pushed:
```bash
git add .
git commit -m "test webhook trigger"
git push origin main
```
This automatically triggered the Jenkins pipeline.

---
## 🔐 Security Considerations

Webhook integration introduces external access into the CI/CD pipeline, so security controls were considered:

* Restricted webhook access to trusted GitHub events
* Jenkins protected using authentication
* No public exposure of internal cluster endpoints
* Controlled CI/CD permissions

---
## 📡 Event Payload Example

A typical GitHub webhook payload includes:

* Repository information
* Commit details
* Author information
* Branch reference

This is used by Jenkins to trigger the correct pipeline execution.