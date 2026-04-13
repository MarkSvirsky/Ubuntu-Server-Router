# 🌐 Ubuntu Server Home Router & Gateway

## Project Overview
This repository contains the configuration files and automation scripts used to transform a standard Ubuntu Linux server into a fully functional, enterprise-grade home router and gateway. 

Instead of relying on off-the-shelf consumer routers, this project manages my entire home network infrastructure. It utilizes a **GitOps** approach: network changes are pushed to this repository, validated by a Jenkins CI/CD pipeline inside isolated Docker containers, and then automatically pulled and applied by the router via systemd services.

**Core Technologies:**
* **Netplan:** Interface configuration and routing.
* **Dnsmasq:** Local DNS resolution and DHCP server.
* **IPTables:** Stateful firewall and NAT (Masquerading) to share the WAN connection.
* **Jenkins & Docker:** Automated testing of network configs before deployment.
* **Bash & Systemd:** Automated synchronization from GitHub to production (`/etc/`).

---

# Files and their purpose

## dnsmasq/server-gateway.conf
DNS and DHCP settings for the server

## netplan .yaml file
Tells the server exactly how each NIC is configured
Their IP, DG, DNS

## routing /configs/routing
Firewall and packet forwarding
Uses iptables-restore to apply a MASQUERADE rule on the WAN interface, allowing the whole house to share the single ISP connection. It also forces ip_forward=1 at the kernel level.

## scripts/git-sync.sh
Updates the files from the git repo into the server's etc files

## sudoers/git-sync
The visudo config allows the systemd task to run git-sync.sh as "mark" without needing a human to type the password

## systemd service
runs git-sync.sh when needed

## Jenkins 
Contains the jenkinsfile and the commands needed in order to allow the Jenkin container to perform the tests in the jenkinsfile
