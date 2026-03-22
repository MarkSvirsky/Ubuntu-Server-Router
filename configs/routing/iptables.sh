*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A PREROUTING -d 172.18.0.2/32 ! -i br-c10e951d4035 -j DROP
COMMIT

*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]

# 1. Allow established connections (Crucial for stability)
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 2. THE RULE JENKINS IS LOOKING FOR
-A INPUT -p tcp --dport 22 -j ACCEPT

# 3. Allow Jenkins UI
-A INPUT -p tcp --dport 8080 -j ACCEPT

# ... the rest of your rules ...

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o enp5s0 -j MASQUERADE
COMMIT
