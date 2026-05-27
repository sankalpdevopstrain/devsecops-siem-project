#!/bin/bash

# ============================================================
# DevSecOps EC2 — Simulated Alert Events
# Injects high/critical alert events without touching the EC2
# ============================================================

SIEM_URL="https://previous-stinky-maturity.ngrok-free.dev/logs"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

send_log() {
    curl -s -X POST "$SIEM_URL" \
        -H "Content-Type: application/json" \
        -d "$1" > /dev/null
    echo -e "  ${GREEN}✔${NC} Sent: $2"
    sleep 0.6
}

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   EC2 Simulated Alert Injector            ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

echo -e "${YELLOW}[HIGH SEVERITY — Failed Logins]${NC}"

send_log '{"type":"failed_login","source":"ec2","message":"Failed SSH login attempt","user":"root","source_ip":"185.220.101.45","service":"SSH","attempt":1}' \
  "Failed SSH login - root from 185.220.101.45"

send_log '{"type":"failed_login","source":"ec2","message":"Failed SSH login attempt","user":"admin","source_ip":"194.165.16.78","service":"SSH","attempt":1}' \
  "Failed SSH login - admin from 194.165.16.78"

send_log '{"type":"failed_login","source":"ec2","message":"Repeated failed SSH login - possible brute force","user":"root","source_ip":"185.220.101.45","service":"SSH","attempt":5}' \
  "Brute force detected - root from 185.220.101.45"

send_log '{"type":"failed_login","source":"ec2","message":"Failed SSH login attempt","user":"ubuntu","source_ip":"45.142.212.100","service":"SSH","attempt":1}' \
  "Failed SSH login - ubuntu from 45.142.212.100"

echo ""
echo -e "${RED}[CRITICAL SEVERITY — System Errors]${NC}"

send_log '{"level":"error","source":"ec2","message":"Memory usage critical — exceeded 90% threshold","service":"ec2-monitor","memory_used_mb":940,"memory_total_mb":1024,"threshold_percent":90}' \
  "Critical memory usage"

send_log '{"level":"error","source":"ec2","message":"Disk usage exceeded 85% on root volume","service":"ec2-monitor","disk_used_gb":6.8,"disk_total_gb":8,"mount":"/"}' \
  "Critical disk usage"

send_log '{"level":"error","source":"ec2","message":"Unexpected process termination detected","service":"siem-shipper","pid":2841,"exit_code":137}' \
  "Process terminated unexpectedly"

send_log '{"level":"error","source":"ec2","message":"Network connection refused — SIEM unreachable","service":"siem-shipper","destination":"previous-stinky-maturity.ngrok-free.dev","retry_attempt":3}' \
  "Network connection error"

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   Alert events injected successfully!     ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "  Check your dashboard: ${GREEN}http://localhost:8081${NC}"
echo ""
