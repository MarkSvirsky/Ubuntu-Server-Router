# 1. Assign an IP to the USB adapter
sudo ip addr add 192.168.1.200/24 dev enx503eaae32369

# 2. Explicitly force 192.168.1.1 traffic through the USB adapter (bypassing D-Link)
sudo ip route add 192.168.1.1/32 dev enx503eaae32369

# ssh to the server in case of netplan error via secondary network card
