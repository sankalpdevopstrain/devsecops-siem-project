#!/bin/bash

# ==================================================
# DevSecOps SIEM — Windows Host Log Shipper
# Continuously ships real local system events to SIEM
# Buffers logs when SIEM is offline, replays on reconnect
# ==================================================

SIEM_URL="http://localhost:8081/logs"
BUFFER_FILE="$HOME/github/platform-logs/host-log-buffer.json"
LOG_FILE="$HOME/github/platform-logs/host-shipper.log"
INTERVAL=10  # seconds between each collection

mkdir -p "$HOME/github/platform-logs"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Host log shipper started" | tee -a "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SIEM URL: $SIEM_URL" | tee -a "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Buffer: $BUFFER_FILE" | tee -a "$LOG_FILE"
echo "--------------------------------------------" | tee -a "$LOG_FILE"

# ==================================================
# SHIP A LOG — with buffering if SIEM is offline
# ==================================================
ship_log() {
    local payload="$1"

    # Try to ship to SIEM
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$SIEM_URL" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        --connect-timeout 3 \
        --max-time 5 2>/dev/null)

    if [ "$response" = "200" ]; then
        echo "[$(date '+%H:%M:%S')] SHIPPED: $payload" | tee -a "$LOG_FILE"
    else
        # SIEM offline — save to buffer
        echo "$payload" >> "$BUFFER_FILE"
        echo "[$(date '+%H:%M:%S')] BUFFERED (SIEM offline): $payload" | tee -a "$LOG_FILE"
    fi
}

# ==================================================
# REPLAY BUFFER — flush queued logs when SIEM is back
# ==================================================
replay_buffer() {
    if [ ! -f "$BUFFER_FILE" ] || [ ! -s "$BUFFER_FILE" ]; then
        return
    fi

    # Test if SIEM is reachable
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        "$SIEM_URL" \
        --connect-timeout 3 \
        --max-time 5 2>/dev/null)

    if [ "$response" != "200" ]; then
        return
    fi

    echo "[$(date '+%H:%M:%S')] SIEM back online — replaying buffer..." | tee -a "$LOG_FILE"

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        curl -s -o /dev/null \
            -X POST "$SIEM_URL" \
            -H "Content-Type: application/json" \
            -d "$line" \
            --connect-timeout 3 \
            --max-time 5 2>/dev/null
        echo "[$(date '+%H:%M:%S')] REPLAYED: $line" | tee -a "$LOG_FILE"
        sleep 0.2
    done < "$BUFFER_FILE"

    # Clear buffer after replay
    > "$BUFFER_FILE"
    echo "[$(date '+%H:%M:%S')] Buffer cleared — all logs replayed" | tee -a "$LOG_FILE"
}

# ==================================================
# COLLECT CPU + MEMORY
# ==================================================
collect_system_metrics() {
    # CPU usage (via wmic)
    cpu=$(wmic cpu get loadpercentage /value 2>/dev/null | grep '=' | cut -d'=' -f2 | tr -d '\r\n ')

    # Memory (via wmic)
    total_mem=$(wmic computersystem get TotalPhysicalMemory /value 2>/dev/null | grep '=' | cut -d'=' -f2 | tr -d '\r\n ')
    free_mem=$(wmic OS get FreePhysicalMemory /value 2>/dev/null | grep '=' | cut -d'=' -f2 | tr -d '\r\n ')

    if [ -n "$cpu" ] && [ -n "$total_mem" ] && [ -n "$free_mem" ]; then
        total_mb=$((total_mem / 1024 / 1024))
        free_mb=$((free_mem / 1024))
        used_mb=$((total_mb - free_mb))
        mem_pct=$(( (used_mb * 100) / total_mb ))

        # Determine severity
        severity="low"
        if [ "$cpu" -gt 85 ] || [ "$mem_pct" -gt 85 ]; then
            severity="critical"
        elif [ "$cpu" -gt 60 ] || [ "$mem_pct" -gt 70 ]; then
            severity="high"
        fi

        payload="{\"source\":\"windows-host\",\"type\":\"system_metrics\",\"severity\":\"$severity\",\"cpu_pct\":$cpu,\"memory_used_mb\":$used_mb,\"memory_total_mb\":$total_mb,\"memory_pct\":$mem_pct,\"host\":\"$HOSTNAME\",\"message\":\"CPU: ${cpu}% | Memory: ${mem_pct}% (${used_mb}MB / ${total_mb}MB)\"}"
        ship_log "$payload"
    fi
}

# ==================================================
# COLLECT DISK USAGE
# ==================================================
collect_disk_metrics() {
    disk_info=$(wmic logicaldisk where "DeviceID='C:'" get FreeSpace,Size /value 2>/dev/null)
    free=$(echo "$disk_info" | grep 'FreeSpace=' | cut -d'=' -f2 | tr -d '\r\n ')
    size=$(echo "$disk_info" | grep '^Size=' | cut -d'=' -f2 | tr -d '\r\n ')

    if [ -n "$free" ] && [ -n "$size" ] && [ "$size" -gt 0 ]; then
        free_gb=$((free / 1024 / 1024 / 1024))
        size_gb=$((size / 1024 / 1024 / 1024))
        used_gb=$((size_gb - free_gb))
        used_pct=$(( (used_gb * 100) / size_gb ))

        severity="low"
        if [ "$used_pct" -gt 90 ]; then
            severity="critical"
        elif [ "$used_pct" -gt 75 ]; then
            severity="high"
        fi

        payload="{\"source\":\"windows-host\",\"type\":\"disk_usage\",\"severity\":\"$severity\",\"drive\":\"C:\",\"used_gb\":$used_gb,\"free_gb\":$free_gb,\"total_gb\":$size_gb,\"used_pct\":$used_pct,\"host\":\"$HOSTNAME\",\"message\":\"Disk C: ${used_pct}% used (${used_gb}GB / ${size_gb}GB)\"}"
        ship_log "$payload"
    fi
}

# ==================================================
# COLLECT NETWORK CONNECTIONS
# ==================================================
collect_network() {
    # Count active TCP connections
    conn_count=$(netstat -n 2>/dev/null | grep "ESTABLISHED" | wc -l | tr -d ' ')

    if [ -n "$conn_count" ]; then
        severity="low"
        if [ "$conn_count" -gt 100 ]; then
            severity="high"
        fi

        payload="{\"source\":\"windows-network\",\"type\":\"network_connections\",\"severity\":\"$severity\",\"established_connections\":$conn_count,\"host\":\"$HOSTNAME\",\"message\":\"Active TCP connections: $conn_count\"}"
        ship_log "$payload"
    fi
}

# ==================================================
# COLLECT RUNNING PROCESS COUNT
# ==================================================
collect_processes() {
    proc_count=$(tasklist 2>/dev/null | tail -n +4 | wc -l | tr -d ' ')

    if [ -n "$proc_count" ]; then
        severity="low"
        if [ "$proc_count" -gt 300 ]; then
            severity="high"
        fi

        payload="{\"source\":\"windows-process\",\"type\":\"process_count\",\"severity\":\"$severity\",\"process_count\":$proc_count,\"host\":\"$HOSTNAME\",\"message\":\"Running processes: $proc_count\"}"
        ship_log "$payload"
    fi
}

# ==================================================
# COLLECT UPTIME
# ==================================================
collect_uptime() {
    uptime_info=$(net stats workstation 2>/dev/null | grep "Statistics since" | sed 's/Statistics since //')
    if [ -n "$uptime_info" ]; then
        payload="{\"source\":\"windows-host\",\"type\":\"uptime\",\"severity\":\"low\",\"since\":\"$uptime_info\",\"host\":\"$HOSTNAME\",\"message\":\"System online since: $uptime_info\"}"
        ship_log "$payload"
    fi
}

# ==================================================
# MAIN LOOP
# ==================================================
echo "Starting continuous collection every ${INTERVAL}s — press Ctrl+C to stop"
echo ""

counter=0

while true; do
    counter=$((counter + 1))
    echo "" | tee -a "$LOG_FILE"
    echo "=== Collection #$counter at $(date '+%H:%M:%S') ===" | tee -a "$LOG_FILE"

    # Replay any buffered logs first
    replay_buffer

    # Collect all metrics
    collect_system_metrics
    collect_network
    collect_processes

    # Collect disk and uptime every 5 cycles (less frequent)
    if [ $((counter % 5)) -eq 0 ]; then
        collect_disk_metrics
        collect_uptime
    fi

    sleep "$INTERVAL"
done
