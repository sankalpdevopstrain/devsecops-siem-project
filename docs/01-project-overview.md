# 🛡 DevSecOps SIEM Project Overview
- [🛡 DevSecOps SIEM Project Overview](#-devsecops-siem-project-overview)
  - [Project Summary](#project-summary)
  - [Business Problem](#business-problem)
  - [Technical Objectives](#technical-objectives)
    - [1. CI/CD Automation](#1-cicd-automation)
    - [2. Container Security](#2-container-security)
    - [3. Orchestration](#3-orchestration)
    - [4. Security Monitoring](#4-security-monitoring)
    - [5. Visualisation](#5-visualisation)
  - [Technologies Used](#technologies-used)
  - [Skills Demonstrated](#skills-demonstrated)
  - [Architecture diagram](#architecture-diagram)
  - [Explanation of the Architecture Diagram](#explanation-of-the-architecture-diagram)

## Project Summary

This project was designed to simulate a real-world DevSecOps environment where application delivery, infrastructure automation, and security monitoring are integrated into a single workflow.

The goal was to build a cloud-native security platform capable of:

- Automating CI/CD deployments
- Running containerised applications
- Orchestrating workloads using Kubernetes
- Ingesting and analysing security events
- Visualising alerts in a custom SIEM dashboard

---

## Business Problem

Traditional deployments often separate development, operations, and security teams.

This creates challenges such as:

- Slow deployments
- Poor visibility into infrastructure events
- Delayed security detection
- Manual operational overhead

This project solves that by integrating security monitoring directly into the deployment pipeline.

---

## Technical Objectives

This project was built to achieve the following:

### 1. CI/CD Automation
Automate build and deployment workflows using Jenkins.

### 2. Container Security
Package applications into Docker containers for consistency.

### 3. Orchestration
Deploy workloads into Kubernetes for scalability and resilience.

### 4. Security Monitoring
Simulate SIEM behaviour by collecting logs from:

- Application events
- Authentication events
- Jenkins pipeline events
- GitHub webhook events

### 5. Visualisation
Display live events inside a browser-based dashboard.

---

## Technologies Used

| Technology | Purpose |
|------------|---------|
| Node.js | SIEM dashboard application |
| Express | API + UI backend |
| Docker | Containerisation |
| Kubernetes | Container orchestration |
| Jenkins | CI/CD automation |
| GitHub | Source control + webhook trigger |
| ngrok | External webhook tunnelling |
| ELK concepts | Logging architecture inspiration |

---

## Skills Demonstrated

This project demonstrates:

- DevSecOps engineering
- Infrastructure automation
- Kubernetes operations
- Secure deployment practices
- Log ingestion pipelines
- Security event analysis

---
## Architecture diagram
![DevSecops SIEM Platform](image.png)

## Explanation of the Architecture Diagram

The architecture follows a secure DevSecOps delivery model, where application development, deployment automation, and security monitoring are integrated into a single operational workflow.

The process begins with a developer committing code changes to GitHub. A GitHub webhook then triggers Jenkins, which acts as the CI/CD orchestrator responsible for validating the codebase, executing pipeline stages, and building the application container image.

Once successfully built, the Docker image is deployed into a Kubernetes environment, where the application runs across containerised workloads designed for scalability, resilience, and service availability.

As the platform operates, security-relevant telemetry is continuously generated from multiple sources, including:

- Application runtime events
- Authentication and access events
- Jenkins pipeline execution logs
- GitHub repository activity

These events are ingested by the SIEM monitoring layer, where they are normalised, analysed, and displayed through the custom security dashboard.

This architecture demonstrates how security can be embedded directly into the software delivery lifecycle, enabling faster deployments, improved visibility, and proactive threat detection.
