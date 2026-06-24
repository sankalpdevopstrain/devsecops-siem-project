#!/bin/bash
# ============================================================
# DevSecOps Platform — Shutdown Script
# Author: Sankalp Hiregoudar
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_DIR="$HOME/github/platform-logs"

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   DevSecOps Platform — Shutting Down...   ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# Stop ngrok
echo -e "${YELLOW}[1/4] Stopping ngrok...${NC}"
taskkill //IM ngrok.exe //F > /dev/null 2>&1 && \
    echo -e "${GREEN}      ngrok stopped.${NC}" || \
    echo -e "      ngrok was not running."

# Stop port-forward
echo -e "${YELLOW}[2/4] Stopping kubectl port-forward...${NC}"
existing_pf=$(lsof -ti:8081 2>/dev/null || true)
if [ -n "$existing_pf" ]; then
    kill "$existing_pf" 2>/dev/null && \
        echo -e "${GREEN}      Port-forward stopped.${NC}"
else
    echo -e "      Port-forward was not running."
fi

# Stop Jenkins
echo -e "${YELLOW}[3/4] Stopping Jenkins container...${NC}"
docker stop jenkins > /dev/null 2>&1 && \
    echo -e "${GREEN}      Jenkins stopped.${NC}" || \
    echo -e "      Jenkins was not running."

# Stop host log shipper
echo -e "${YELLOW}[4/4] Stopping host log shipper...${NC}"
if [ -f "$LOG_DIR/host-shipper.pid" ]; then
    OLD_PID=$(cat "$LOG_DIR/host-shipper.pid")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" > /dev/null 2>&1 && \
            echo -e "${GREEN}      Host log shipper stopped (PID: $OLD_PID).${NC}"
    else
        echo -e "      Host log shipper was not running."
    fi
    rm -f "$LOG_DIR/host-shipper.pid"
else
    echo -e "      Host log shipper was not running."
fi

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   Platform shut down cleanly.             ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
