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

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   DevSecOps Platform — Shutting Down...   ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# Stop ngrok
echo -e "${YELLOW}[1/3] Stopping ngrok...${NC}"
taskkill //IM ngrok.exe //F > /dev/null 2>&1 && \
    echo -e "${GREEN}      ngrok stopped.${NC}" || \
    echo -e "      ngrok was not running."

# Stop port-forward
echo -e "${YELLOW}[2/3] Stopping kubectl port-forward...${NC}"
existing_pf=$(lsof -ti:8081 2>/dev/null || true)
if [ -n "$existing_pf" ]; then
    kill "$existing_pf" 2>/dev/null && \
        echo -e "${GREEN}      Port-forward stopped.${NC}"
else
    echo -e "      Port-forward was not running."
fi

# Stop Jenkins
echo -e "${YELLOW}[3/3] Stopping Jenkins container...${NC}"
docker stop jenkins > /dev/null 2>&1 && \
    echo -e "${GREEN}      Jenkins stopped.${NC}" || \
    echo -e "      Jenkins was not running."

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   Platform shut down cleanly.             ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
