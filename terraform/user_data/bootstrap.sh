#!/bin/bash

# ============================================================
# DevSecOps EC2 Bootstrap Script
# Runs automatically on first boot via Terraform user_data
# Installs: Docker, Node.js, log shipper
# Ships real EC2 logs to your SIEM dashboard
# ============================================================

set -e

SIEM_URL="${siem_url}/logs"
LOG_FILE="/var/log/devsecops-shipper.log"

echo "=== DevSecOps EC2 Bootstrap Starting ===" >> $LOG_FILE

# ── Update system ─────────────────────────────────────────────
apt-get update -y
apt-get upgrade -y

# ── Install Docker ────────────────────────────────────────────
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

echo "=== Docker installed ===" >> $LOG_FILE

# ── Install Node.js ───────────────────────────────────────────
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

echo "=== Node.js installed ===" >> $LOG_FILE

# ── Install curl (for log shipping) ──────────────────────────
apt-get install -y curl jq

# ── Send boot log to SIEM ─────────────────────────────────────
send_log() {
  local payload=$1
  curl -s -X POST "$SIEM_URL" \
    -H "Content-Type: application/json" \
    -d "$payload" >> $LOG_FILE 2>&1 || true
}

# Boot event
send_log "{\"type\":\"ec2_boot\",\"source\":\"ec2\",\"message\":\"EC2 instance booted successfully\",\"instance_id\":\"$(curl -s http://169.254.169.254/latest/meta-data/instance-id)\",\"public_ip\":\"$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)\",\"region\":\"eu-west-2\"}"

# Docker install success
send_log "{\"type\":\"login_success\",\"source\":\"ec2\",\"message\":\"Docker installed and started on EC2\",\"service\":\"docker\"}"

# Node.js install success
send_log "{\"type\":\"login_success\",\"source\":\"ec2\",\"message\":\"Node.js 18 installed on EC2\",\"service\":\"nodejs\"}"

echo "=== Boot logs shipped to SIEM ===" >> $LOG_FILE

# ── Create log shipper service ────────────────────────────────
cat > /usr/local/bin/siem-shipper.sh << 'SHIPPER'
#!/bin/bash

SIEM_URL="SIEM_URL_PLACEHOLDER/logs"

send_log() {
  curl -s -X POST "$SIEM_URL" \
    -H "Content-Type: application/json" \
    -d "$1" > /dev/null 2>&1 || true
}

# Monitor auth log for failed logins
tail -F /var/log/auth.log 2>/dev/null | while read line; do
  if echo "$line" | grep -q "Failed password"; then
    USER=$(echo "$line" | grep -oP "for \K\w+")
    IP=$(echo "$line" | grep -oP "from \K[\d.]+")
    send_log "{\"type\":\"failed_login\",\"source\":\"ec2\",\"message\":\"Failed SSH login attempt\",\"user\":\"$USER\",\"source_ip\":\"$IP\",\"service\":\"SSH\"}"
  fi

  if echo "$line" | grep -q "Accepted password\|Accepted publickey"; then
    USER=$(echo "$line" | grep -oP "for \K\w+")
    IP=$(echo "$line" | grep -oP "from \K[\d.]+")
    send_log "{\"type\":\"login_success\",\"source\":\"ec2\",\"message\":\"Successful SSH login\",\"user\":\"$USER\",\"source_ip\":\"$IP\",\"service\":\"SSH\"}"
  fi
done
SHIPPER

# Replace placeholder with actual SIEM URL
sed -i "s|SIEM_URL_PLACEHOLDER|${siem_url}|g" /usr/local/bin/siem-shipper.sh
chmod +x /usr/local/bin/siem-shipper.sh

# ── Create systemd service for log shipper ────────────────────
cat > /etc/systemd/system/siem-shipper.service << 'SERVICE'
[Unit]
Description=DevSecOps SIEM Log Shipper
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/siem-shipper.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable siem-shipper
systemctl start siem-shipper

echo "=== SIEM log shipper service started ===" >> $LOG_FILE
echo "=== Bootstrap complete ===" >> $LOG_FILE
