*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A PREROUTING -d 172.18.0.2/32 ! -i br-c10e951d4035 -j DROP
COMMIT

*filter
# 1. Keep your current session alive (CRITICAL)
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 2. Allow SSH (So the Jenkins 'Lockout Test' passes)
-A INPUT -p tcp --dport 22 -j ACCEPT

# 3. Allow Jenkins UI (So you don't lose the dashboard)
-A INPUT -p tcp --dport 8080 -j ACCEPT
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A FORWARD -i enp1s0 -o enp5s0 -j ACCEPT
-A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
COMMIT

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o enp5s0 -j MASQUERADE
COMMIT
