# Docker Containerisation and Build Process
- [Docker Containerisation and Build Process](#docker-containerisation-and-build-process)
  - [Containerisation Objective](#containerisation-objective)
  - [Why Docker Was Used](#why-docker-was-used)
  - [Docker Build Process](#docker-build-process)
    - [Stage 1 — Application Preparation](#stage-1--application-preparation)
    - [Stage 2 — Docker Image Build](#stage-2--docker-image-build)
    - [Stage 3 — Container Validation](#stage-3--container-validation)
    - [Stage 4 — Deployment Preparation](#stage-4--deployment-preparation)
  - [Implementation Steps](#implementation-steps)
    - [Step 1](#step-1)
    - [Step 2](#step-2)
    - [Step 3](#step-3)
    - [Step 4](#step-4)
    - [Step 5](#step-5)
    - [Step 6](#step-6)
  - [Security Considerations](#security-considerations)
  - [Container Architecture Diagram](#container-architecture-diagram)
  - [Diagram Explanation](#diagram-explanation)

---

## Containerisation Objective

Docker was implemented to package the SIEM application into a portable and consistent runtime environment.

The objective was to ensure that the application could run reliably across development, testing, and production environments without dependency conflicts.

Key goals:

- Environment consistency
- Dependency isolation
- Portable deployments
- Simplified Kubernetes deployment

---

## Why Docker Was Used

Traditional application deployments often suffer from:

- Environment drift
- Missing dependencies
- Runtime inconsistencies
- Manual configuration errors

Docker solves these issues by packaging:

- Application source code
- Runtime dependencies
- Node.js environment
- Startup configuration

into a single container image.

---

## Docker Build Process

The Docker workflow followed these stages:

### Stage 1 — Application Preparation

The Node.js application was prepared by defining:

- Application source files
- package.json dependencies
- Startup configuration

---

### Stage 2 — Docker Image Build

The application image was built using:

```bash
docker build -t devsecops-siem-app .
```

This created a portable container image.

---

### Stage 3 — Container Validation

The container was tested locally before deployment.

Validation included:

- Container startup
- Port exposure
- Application health check

Example command:

```bash
docker run -p 3000:3000 devsecops-siem-app
```

---

### Stage 4 — Deployment Preparation

The validated image was then prepared for Kubernetes deployment.

This allowed the same container to be used throughout the deployment lifecycle.

---

## Implementation Steps

### Step 1

Created a Dockerfile inside the application directory.

### Step 2

Defined the Node.js runtime environment.

### Step 3

Copied application source code into the container.

### Step 4

Installed dependencies inside the image.

### Step 5

Exposed application port 3000.

### Step 6

Configured container startup using Node.js.

---

## Security Considerations

The container build process followed security best practices:

- Isolated runtime environment
- Reduced host dependency exposure
- Predictable runtime behaviour
- Easier vulnerability scanning
- Consistent deployment artifacts

This reduces operational and security risks.

---

## Container Architecture Diagram

![Docker Architecture Diagram](image-3.png)

---

## Diagram Explanation

The Docker architecture begins with the application source code and dependency definitions.

Docker then builds a container image that packages:

- Application source code
- Node.js runtime
- Installed dependencies
- Startup configuration

The resulting container image becomes the deployment artifact used by Kubernetes.

When the container starts, the SIEM application begins listening on port 3000 and starts processing security events.

This architecture ensures consistency, portability, and secure application delivery across environments.