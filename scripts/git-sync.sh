#!/bin/bash

# Configuration
REPO_DIR="/home/mark/git-main/Ubuntu-Server-Router"
LOG_FILE="/var/log/git-sync.log"

echo "$(date): Starting Sync from GitHub..." >> "$LOG_FILE"

# 1. Update the Local Repo
cd "$REPO_DIR" || exit
git fetch origin main
git reset --hard origin/main >> "$LOG_FILE" 2>&1

# 2. Deploy Netplan
echo "Deploying Netplan..." >> "$LOG_FILE"
cp configs/netplan/*.yaml /etc/netplan/
netplan apply >> "$LOG_FILE" 2>&1

# 3. Deploy DNSMasq
echo "Deploying Dnsmasq..." >> "$LOG_FILE"
cp configs/dnsmasq/server-gateway.conf /etc/dnsmasq.d/
systemctl restart dnsmasq >> "$LOG_FILE" 2>&1

# 4. Deploy Firewall (IPTables)
echo "Deploying IPTables..." >> "$LOG_FILE"
# Note: This assumes iptables-persistent is installed to save rules
iptables-restore < configs/routing/iptables.sh
iptables-save > /etc/iptables/rules.v4

echo "$(date): Deployment Successful." >> "$LOG_FILE"
