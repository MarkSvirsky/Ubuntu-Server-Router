# Files and their purpose

## dnsmasq/server-gateway.conf
DNS and DHCP settings for the server

## netplan .yaml file
Tells the server exactly how each NIC is configured
Ther IP, DG, DNS

## routing /configs/routing
Firewall and packet forwarding
Uses iptables-restore to apply a MASQUERADE rule on the WAN interface, allowing the whole house to share the single ISP connection. It also forces ip_forward=1 at the kernel level.

## scripts/git-sync.sh
Continuous Deployment (CD) logic
Compares local git repo to the remote repo
If changes are detected it will carefully update the config files on the server

## sudoers/git-sync
The visudo config allows the systemd task to run git-sync.sh as "mark" without needing a human to type the password

## systemd service and timer
Every 60 seconds it runs git-sync.sh to ensure changes and pushed from Arch PC to ubuntu server
