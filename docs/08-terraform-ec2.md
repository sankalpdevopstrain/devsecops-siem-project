# ☁ Terraform + AWS EC2

---

## Overview

The AWS EC2 instance is provisioned entirely through Terraform — no manual steps in the AWS console. This demonstrates Infrastructure as Code (IaC), a core DevSecOps engineering practice.

Once running, the EC2 instance ships real system logs directly into the SIEM dashboard via the ngrok tunnel.

---

## Why Terraform

Manually provisioning infrastructure through a web console is not reproducible, not auditable, and not scalable. Terraform solves this by:

- Defining infrastructure as version-controlled code
- Allowing identical environments to be rebuilt from scratch
- Providing a clear `plan` before any changes are applied
- Enabling clean teardown with `terraform destroy`

---

## What Terraform Provisions

```
AWS eu-west-2 (London)
│
├── VPC (10.0.0.0/16)
│   ├── Public Subnet (10.0.1.0/24) — eu-west-2a
│   ├── Internet Gateway
│   └── Route Table (0.0.0.0/0 → IGW)
│
├── Security Group
│   ├── Port 22  — SSH
│   ├── Port 80  — HTTP
│   ├── Port 443 — HTTPS
│   └── Port 3000 — Node.js app
│
├── SSH Key Pair (managed by Terraform)
│
└── EC2 Instance
    ├── AMI: Ubuntu 26.04 LTS
    ├── Type: t3.micro (free tier)
    └── user_data: bootstrap.sh (auto-installs Docker + Node.js)
```

---

## Deployment Commands

```bash
cd terraform/

# Initialise — downloads AWS provider
terraform init

# Preview — shows exactly what will be created
terraform plan

# Deploy — provisions all 8 resources
terraform apply
```

Output after successful apply:

```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:
ec2_public_ip  = "3.8.210.149"
ec2_public_dns = "ec2-3-8-210-149.eu-west-2.compute.amazonaws.com"
ssh_command    = "ssh -i ~/.ssh/devsecops-key.pem ubuntu@3.8.210.149"
siem_dashboard = "http://localhost:8081"
```

---

## Connecting to EC2

```bash
ssh -i ~/.ssh/devsecops-key.pem ubuntu@3.8.210.149
```

---

## Shipping Real Logs to SIEM

A `log` helper function is installed permanently on the EC2 instance. Any manual or automated command can be annotated and shipped to the SIEM dashboard in real time.

```bash
# Real system activity
sudo apt-get update
log "apt-get update completed successfully"

sudo apt-get upgrade -y
log "System packages upgraded"

# The log appears instantly in the SIEM dashboard at http://localhost:8081
```

---

## EC2 Activity Script

For a comprehensive system health report shipped to the SIEM in one command:

```bash
./ec2-activity.sh
```

This runs `apt-get update`, `apt-get upgrade`, checks running services, scans open ports, and ships all results to the dashboard.

---

## Simulated Alert Events

To demonstrate high and critical severity events without affecting the EC2:

```bash
./ec2-alerts.sh
```

Injects: failed SSH login attempts, brute force detection, memory threshold breach, disk usage warning, and connection errors.

---

## Starting EC2 After a Restart

The EC2 may stop overnight to conserve resources. To restart:

```bash
# Check status
aws ec2 describe-instances \
  --instance-ids i-09f0bdec9750547c7 \
  --query "Reservations[*].Instances[*].[State.Name,PublicIpAddress]" \
  --output table \
  --region eu-west-2

# Start if stopped
aws ec2 start-instances \
  --instance-ids i-09f0bdec9750547c7 \
  --region eu-west-2
```

---

## Teardown

When the project is complete, destroy all AWS resources to avoid charges:

```bash
terraform destroy
```

This removes all 8 provisioned resources cleanly — VPC, subnet, internet gateway, route table, security group, key pair, and EC2 instance.

---

## Cost

The EC2 t3.micro instance is covered by the AWS free tier — 750 hours per month. Running 24/7 for a full month uses exactly 744 hours, staying within the free tier limit.
