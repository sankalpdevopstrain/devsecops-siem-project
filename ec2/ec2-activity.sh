#!/bin/bash

# ============================================================
# DevSecOps EC2 — Real Activity SIEM Shipper
# Run real EC2 commands and ship results to SIEM dashboard
# Usage: ./ec2-activity.sh
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
}

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   EC2 Real Activity Monitor               ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# ── SYSTEM INFO ───────────────────────────────────────────────
echo -e "${GREEN}[1/5] Collecting system info...${NC}"

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "i-09f0bdec9750547c7")
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "3.8.210.149")
UPTIME=$(uptime -p)
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEM_USED=$(free -m | awk 'NR==2{print $3}')
MEM_TOTAL=$(free -m | awk 'NR==2{print $2}')
DISK_USED=$(df -h / | awk 'NR==2{print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
DISK_PERCENT=$(df / | awk 'NR==2{print $5}' | tr -d '%')

send_log "{\"type\":\"health_check\",\"source\":\"ec2\",\"message\":\"EC2 system health check\",\"instance_id\":\"$INSTANCE_ID\",\"public_ip\":\"$PUBLIC_IP\",\"uptime\":\"$UPTIME\",\"cpu_percent\":$CPU,\"memory_used_mb\":$MEM_USED,\"memory_total_mb\":$MEM_TOTAL,\"disk_used\":\"$DISK_USED\",\"disk_total\":\"$DISK_TOTAL\"}"

echo -e "  ${GREEN}✔${NC} System info shipped to SIEM"

# ── APT UPDATE ────────────────────────────────────────────────
echo -e "${GREEN}[2/5] Running apt-get update...${NC}"

send_log "{\"type\":\"login_success\",\"source\":\"ec2\",\"message\":\"apt-get update started — fetching latest package lists\",\"service\":\"apt\",\"instance_id\":\"$INSTANCE_ID\"}"

UPDATE_OUTPUT=$(sudo apt-get update 2>&1)
UPDATE_HITS=$(echo "$UPDATE_OUTPUT" | grep -c "Hit:" || true)
UPDATE_GET=$(echo "$UPDATE_OUTPUT" | grep -c "Get:" || true)

echo "$UPDATE_OUTPUT" | tail -3

send_log "{\"type\":\"login_success\",\"source\":\"ec2\",\"message\":\"apt-get update completed\",\"service\":\"apt\",\"packages_hit\":$UPDATE_HITS,\"packages_fetched\":$UPDATE_GET,\"status\":\"success\"}"

echo -e "  ${GREEN}✔${NC} apt update result shipped to SIEM"

# ── APT UPGRADE ───────────────────────────────────────────────
echo -e "${GREEN}[3/5] Running apt-get upgrade...${NC}"

send_log "{\"type\":\"login_success\",\"source\":\"ec2\",\"message\":\"apt-get upgrade started — upgrading packages\",\"service\":\"apt\",\"instance_id\":\"$INSTANCE_ID\"}"

UPGRADE_OUTPUT=$(sudo apt-get upgrade -y 2>&1)
UPGRADED=$(echo "$UPGRADE_OUTPUT" | grep -oP '\d+ upgraded' | grep -oP '\d+' || echo "0")
NEWLY=$(echo "$UPGRADE_OUTPUT" | grep -oP '\d+ newly installed' | grep -oP '\d+' || echo "0")

echo "$UPGRADE_OUTPUT" | tail -3

send_log "{\"type\":\"login_success\",\"source\":\"ec2\",\"message\":\"apt-get upgrade completed\",\"service\":\"apt\",\"packages_upgraded\":\"$UPGRADED\",\"packages_newly_installed\":\"$NEWLY\",\"status\":\"success\"}"

echo -e "  ${GREEN}✔${NC} apt upgrade result shipped to SIEM"

# ── RUNNING SERVICES ──────────────────────────────────────────
echo -e "${GREEN}[4/5] Checking running services...${NC}"

DOCKER_STATUS=$(systemctl is-active docker 2>/dev/null || echo "inactive")
SSH_STATUS=$(systemctl is-active ssh 2>/dev/null || echo "inactive")
SIEM_STATUS=$(systemctl is-active siem-shipper 2>/dev/null || echo "inactive")

send_log "{\"type\":\"login_success\",\"source\":\"ec2\",\"message\":\"Service status check completed\",\"service\":\"systemd\",\"docker\":\"$DOCKER_STATUS\",\"ssh\":\"$SSH_STATUS\",\"siem_shipper\":\"$SIEM_STATUS\"}"

echo -e "  ${GREEN}✔${NC} Service status shipped to SIEM"
echo -e "      Docker: $DOCKER_STATUS | SSH: $SSH_STATUS | SIEM Shipper: $SIEM_STATUS"

# ── OPEN PORTS ────────────────────────────────────────────────
echo -e "${GREEN}[5/5] Checking open ports...${NC}"

OPEN_PORTS=$(ss -tlnp 2>/dev/null | awk 'NR>1{print $4}' | grep -oP ':\K\d+' | sort -n | tr '\n' ',' | sed 's/,$//')

send_log "{\"type\":\"login_success\",\"source\":\"ec2\",\"message\":\"Open port scan completed\",\"source\":\"ec2\",\"service\":\"network\",\"open_ports\":\"$OPEN_PORTS\",\"instance_id\":\"$INSTANCE_ID\"}"

echo -e "  ${GREEN}✔${NC} Open ports shipped to SIEM"
echo -e "      Open ports: $OPEN_PORTS"

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   All real EC2 activity shipped!          ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "  Check your dashboard: ${GREEN}http://localhost:8081${NC}"
echo ""
