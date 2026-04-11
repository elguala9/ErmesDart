#!/bin/sh
set -e

# Address-Restricted Cone NAT
# ====================================
# Characteristics:
# - Static port mapping (same external port for each internal port)
# - Inbound filtering by SOURCE ADDRESS ONLY
# - Allows return traffic from any port of a peer IF that peer's IP
#   was previously used in an outbound connection
# - STUN partially works: discovered address is usable, but filtering
#   may reject if the connecting peer hasn't been contacted first
#
# Implementation: Use conntrack ESTABLISHED,RELATED to track
# bidirectional flows - blocks NEW inbound connections

# Reset iptables to clean state (remove any stale rules from previous tests)
iptables -t nat -F 2>/dev/null || true
iptables -t nat -X 2>/dev/null || true
iptables -F 2>/dev/null || true
iptables -X 2>/dev/null || true

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Static port mapping (MASQUERADE without --random)
iptables -t nat -A POSTROUTING -s 172.30.10.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.30.20.0/24 -o eth0 -j MASQUERADE

# Address-Restricted filtering: Allow return traffic only from
# established connections (conntrack tracks by source IP)
# Block NEW inbound traffic (not return traffic)
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth0 -m conntrack --ctstate NEW -j DROP

echo "[Router] Address-Restricted Cone NAT rules installed"
echo "[Router] Zone-A (172.30.10.0/24) and Zone-B (172.30.20.0/24) masqueraded via 172.30.0.1"
echo "[Router] Port mapping: STATIC (same external port for all destinations)"
echo "[Router] Inbound filtering: BY SOURCE ADDRESS (allows return traffic from known peers)"
echo "[Router] Expected: STUN mostly works, might have issues if peer hasn't contacted yet"

# Keep container alive
exec sleep infinity
