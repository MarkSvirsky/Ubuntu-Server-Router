#!/bin/bash
REPO_PATH="/home/mark/git-main"

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
        
        # Test config before restarting to prevent house-wide outages
        if sudo dnsmasq --test; then
            sudo systemctl restart dnsmasq
            echo "dnsmasq restarted successfully."
        else
            echo "ERROR: New dnsmasq config is invalid! Not restarting."
        fi
    fi

    # 3. Check if netplan changed
    if ! cmp -s "$REPO_PATH/configs/netplan/90-*.yaml" "/etc/netplan/"; then
        echo "Updating Netplan..."
        sudo cp "$REPO_PATH/configs/netplan/*.yaml" "/etc/netplan/"
        sudo netplan apply
    fi
else
    echo "No changes found. Staying quiet."
fi
