#!/bin/bash
REPO_PATH="/home/mark/git-main"
IPTABLES_MARKER="/var/lib/git-sync/iptables.last"

# Ensure marker directory exists
[ ! -d /var/lib/git-sync ] && sudo mkdir -p /var/lib/git-sync

cd $REPO_PATH

# 1. Check for updates from GitHub
git fetch origin main
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Changes detected. Pulling from GitHub..."
    git pull origin main

    # 2. Check if dnsmasq config actually changed
    if ! cmp -s "$REPO_PATH/configs/dnsmasq/server-gateway.conf" "/etc/dnsmasq.d/server-gateway.conf"; then
        echo "Updating dnsmasq config..."
        sudo cp "$REPO_PATH/configs/dnsmasq/server-gateway.conf" "/etc/dnsmasq.d/"
        
        if sudo dnsmasq --test; then
            sudo systemctl restart dnsmasq
            echo "dnsmasq restarted successfully."
        else
            echo "ERROR: New dnsmasq config is invalid! Not restarting."
        fi
    fi

    # 3. Check if netplan changed
    # Fix: Keep the '*' outside of quotes for expansion!
    if ! cmp -s "$REPO_PATH/configs/netplan/"*.yaml /etc/netplan/90-*.yaml; then
        echo "Updating Netplan..."
        sudo cp "$REPO_PATH/configs/netplan/"*.yaml /etc/netplan/
        sudo netplan apply
    fi

    # 4. Check if routing/iptables config changed
    if ! cmp -s "$REPO_PATH/configs/routing/iptables.sh" "$IPTABLES_MARKER"; then
        echo "Updating Firewall/Routing..."
        # We use the 'Direct Binary' approach for cleaner sudoers
	sudo iptables-restore --noflush < "$REPO_PATH/configs/routing/iptables.sh"
        sudo sysctl -w net.ipv4.ip_forward=1
        sudo cp "$REPO_PATH/configs/routing/iptables.sh" "$IPTABLES_MARKER"
    fi

else
    echo "No changes found. Staying quiet."
fi
