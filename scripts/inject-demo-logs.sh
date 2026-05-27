#!/bin/bash

# ============================================================
# DevSecOps SIEM — Demo Log Injector
# Sends realistic low / high / critical events to the dashboard
# ============================================================

SIEM_URL="http://localhost:8081/logs"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   SIEM Demo Log Injector — Starting...    ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

send_log() {
    local label=$1
    local payload=$2
    curl -s -X POST "$SIEM_URL" \
        -H "Content-Type: application/json" \
        -d "$payload" > /dev/null
    echo -e "  ${GREEN}✔${NC} Sent: $label"
    sleep 0.8
}

# ── LOW severity events ───────────────────────────────────────
echo -e "${GREEN}[LOW SEVERITY EVENTS]${NC}"

send_log "Successful login - jenkins-admin" \
  '{"type":"login_success","user":"jenkins-admin","source_ip":"192.168.1.10","service":"Jenkins"}'

send_log "Successful login - deploy-bot" \
  '{"type":"login_success","user":"deploy-bot","source_ip":"192.168.1.12","service":"Kubernetes Dashboard"}'

send_log "CI Build triggered" \
  '{"type":"ci_build","status":"success","job":"devsecops-ci-build","triggered_by":"github_webhook","branch":"main"}'

send_log "Docker image built successfully" \
  '{"type":"docker_build","status":"success","image":"devsecops-app:latest","duration_seconds":12}'

send_log "Kubernetes deployment applied" \
  '{"type":"k8s_deploy","status":"success","deployment":"devsecops-app","replicas":2,"namespace":"default"}'

send_log "GitHub webhook received" \
  '{"type":"github_webhook","event":"push","branch":"main","author":"sankalpdevopstrain","repo":"devsecops-siem-project"}'

send_log "Health check passed" \
  '{"type":"health_check","service":"devsecops-app","status":"healthy","response_ms":23}'

echo ""

# ── HIGH severity events ──────────────────────────────────────
echo -e "${YELLOW}[HIGH SEVERITY EVENTS]${NC}"

send_log "Failed login attempt - admin" \
  '{"type":"failed_login","user":"admin","source_ip":"203.0.113.45","service":"Jenkins","attempt":1}'

send_log "Failed login attempt - root" \
  '{"type":"failed_login","user":"root","source_ip":"198.51.100.23","service":"Jenkins","attempt":1}'

send_log "Failed login attempt - admin (repeat)" \
  '{"type":"failed_login","user":"admin","source_ip":"203.0.113.45","service":"Jenkins","attempt":2}'

send_log "Failed login attempt - deploy-user" \
  '{"type":"failed_login","user":"deploy-user","source_ip":"185.220.101.67","service":"Kubernetes Dashboard","attempt":1}'

echo ""

# ── CRITICAL severity events ──────────────────────────────────
echo -e "${RED}[CRITICAL SEVERITY EVENTS]${NC}"

send_log "Application error - unhandled exception" \
  '{"level":"error","message":"Unhandled exception in request handler","service":"devsecops-app","source_ip":"10.0.0.5","stack":"TypeError: Cannot read property of undefined"}'

send_log "Application error - database connection failed" \
  '{"level":"error","message":"MongoDB connection refused","service":"devsecops-app","host":"mongo:27017","retry_attempt":3}'

send_log "Application error - memory threshold exceeded" \
  '{"level":"error","message":"Memory usage exceeded 90% threshold","service":"devsecops-app","pod":"devsecops-app-7d58c886cf-ffxsg","memory_mb":1450}'

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   All demo logs injected successfully!    ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "  Open your dashboard: ${GREEN}http://localhost:8081${NC}"
echo ""
