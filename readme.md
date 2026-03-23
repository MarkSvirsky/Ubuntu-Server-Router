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
