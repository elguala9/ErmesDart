#!/bin/sh
set -e

# Symmetric NAT
# ================================================
# Characteristics:
# - Port mapping is RANDOMIZED and DESTINATION-DEPENDENT
# - Each outbound connection to a different destination gets a DIFFERENT
#   external port (even from the same internal port to different peers)
# - Inbound filtering by SOURCE ADDRESS AND PORT (quadruplet level)
# - MOST problematic for STUN and hole-punching
# - Requires fallback mechanisms (TURN relay, ICE, etc.)
#
# Implementation: MASQUERADE --random ensures port randomization
# Combined with conntrack for filtering (blocks NEW inbound)

# Reset iptables to clean state (remove any stale rules from previous tests)
iptables -t nat -F 2>/dev/null || true
iptables -t nat -X 2>/dev/null || true
iptables -F 2>/dev/null || true
iptables -X 2>/dev/null || true

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Symmetric NAT with randomized port mapping
# Each new connection to different destination = different external port
iptables -t nat -A POSTROUTING -s 172.30.10.0/24 -o eth0 -j MASQUERADE --random
iptables -t nat -A POSTROUTING -s 172.30.20.0/24 -o eth0 -j MASQUERADE --random

# Strict filtering: only established/related traffic
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth0 -m conntrack --ctstate NEW -j DROP
iptables -A FORWARD -j DROP

echo "[Router] Symmetric NAT rules installed"
echo "[Router] Zone-A (172.30.10.0/24) and Zone-B (172.30.20.0/24) masqueraded via 172.30.0.1"
echo "[Router] Port mapping: RANDOMIZED PER DESTINATION (ephemeral port changes per peer)"
echo "[Router] Inbound filtering: STRICT (address+port quadruplet, NEW traffic blocked)"
echo "[Router] Expected: STUN fails completely, P2P connections fail without TURN fallback"

# Keep container alive
exec sleep infinity
