#!/bin/bash

# ============================================================
# DevSecOps Platform — Startup Script
# Author: Sankalp Hiregoudar
# Description: Starts Jenkins, port-forward, and ngrok tunnel
#              in a single command from Git Bash on Windows.
# ============================================================

set -e

# ── Colour helpers ────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Colour

NGROK_PATH="$HOME/github/ngrok.exe"
LOG_DIR="$HOME/github/platform-logs"
mkdir -p "$LOG_DIR"

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   DevSecOps Platform — Starting Up...     ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# ── Step 1: Start Jenkins container ──────────────────────────
echo -e "${YELLOW}[1/3] Starting Jenkins container...${NC}"

JENKINS_STATUS=$(docker inspect -f '{{.State.Status}}' jenkins 2>/dev/null || echo "missing")

if [ "$JENKINS_STATUS" == "running" ]; then
    echo -e "${GREEN}      Jenkins is already running.${NC}"
elif [ "$JENKINS_STATUS" == "exited" ] || [ "$JENKINS_STATUS" == "created" ]; then
    docker start jenkins > /dev/null 2>&1
    sleep 3
    echo -e "${GREEN}      Jenkins started successfully.${NC}"
else
    echo -e "${RED}      ERROR: Jenkins container not found. Check Docker Desktop is running.${NC}"
    exit 1
fi

# ── Step 2: kubectl port-forward ─────────────────────────────
echo -e "${YELLOW}[2/3] Starting kubectl port-forward (dashboard on :8081)...${NC}"

# Kill any existing process on 8081 (Windows-compatible)
existing_pid=$(netstat -ano 2>/dev/null | grep "127.0.0.1:8081" | awk '{print $5}' | head -1)
if [ -n "$existing_pid" ]; then
    echo "      Clearing existing process on port 8081 (PID: $existing_pid)..."
    taskkill //PID "$existing_pid" //F > /dev/null 2>&1 || true
    sleep 1
fi

kubectl port-forward svc/devsecops-app-service 8081:80 \
    > "$LOG_DIR/port-forward.log" 2>&1 &

PORT_FORWARD_PID=$!
sleep 2

if kill -0 "$PORT_FORWARD_PID" 2>/dev/null; then
    echo -e "${GREEN}      Port-forward running (PID: $PORT_FORWARD_PID).${NC}"
else
    echo -e "${RED}      ERROR: Port-forward failed. Check kubectl and your cluster.${NC}"
    cat "$LOG_DIR/port-forward.log"
    exit 1
fi

# ── Step 3: Start ngrok tunnel ────────────────────────────────
echo -e "${YELLOW}[3/3] Starting ngrok tunnel (Jenkins on :8080)...${NC}"

# Kill any existing ngrok process
if tasklist 2>/dev/null | grep -q "ngrok.exe"; then
    taskkill //IM ngrok.exe //F > /dev/null 2>&1 || true
    sleep 1
fi

"$NGROK_PATH" start --all --config "$HOME/ngrok.yml" \
    > "$LOG_DIR/ngrok.log" 2>&1 &

NGROK_PID=$!
sleep 4

# Fetch the Jenkins public URL
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null \
    | grep -o '"public_url":"[^"]*"' \
    | grep https \
    | head -1 \
    | cut -d'"' -f4)

# Fetch the SIEM public URL
SIEM_NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null \
    | grep -o '"public_url":"[^"]*"' \
    | grep https \
    | tail -1 \
    | cut -d'"' -f4)

if [ -n "$NGROK_URL" ]; then
    echo -e "${GREEN}      ngrok tunnel active.${NC}"
else
    echo -e "${YELLOW}      ngrok started — URL not yet available (check http://127.0.0.1:4040).${NC}"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   Platform Ready                          ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "  Jenkins (local):      ${GREEN}http://localhost:8080${NC}"
echo -e "  Jenkins (public):     ${GREEN}${NGROK_URL:-"Check http://127.0.0.1:4040"}${NC}"
echo -e "  SIEM Dashboard:       ${GREEN}http://localhost:8081${NC}"
echo -e "  SIEM (public/EC2):    ${GREEN}${SIEM_NGROK_URL:-"Check http://127.0.0.1:4040"}${NC}"
echo -e "  ngrok Web UI:         ${GREEN}http://127.0.0.1:4040${NC}"
echo ""
echo -e "  Logs:                 $LOG_DIR/"
echo ""
echo -e "${YELLOW}  Keep this window open, or run stop-platform.sh to shut down.${NC}"
echo ""
