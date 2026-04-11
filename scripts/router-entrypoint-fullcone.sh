#!/bin/sh
set -e

# Full Cone NAT - Endpoint-Independent, Unrestricted
# ========================================================
# Characteristics:
# - Once a mapping is created for internal port → external port,
#   ANY external host can send traffic to that external port
#   and it reaches the internal host
# - Port is STATIC for each internal port (reused across all destinations)
# - STUN works perfectly: discovered address is usable by all remote peers

# Reset iptables to clean state (remove any stale rules from previous tests)
iptables -t nat -F 2>/dev/null || true
iptables -t nat -X 2>/dev/null || true
iptables -F 2>/dev/null || true
iptables -X 2>/dev/null || true

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Simple MASQUERADE - creates static port mapping
# Same internal port → same external port for ALL destinations
iptables -t nat -A POSTROUTING -s 172.30.10.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.30.20.0/24 -o eth0 -j MASQUERADE

echo "[Router] Full Cone NAT rules installed"
echo "[Router] Zone-A (172.30.10.0/24) and Zone-B (172.30.20.0/24) masqueraded via 172.30.0.1"
echo "[Router] Port mapping: STATIC (same external port for all destinations)"
echo "[Router] Inbound filtering: NONE (unrestricted)"
echo "[Router] Expected: STUN works perfectly, all P2P connections succeed"

# Keep container alive
exec sleep infinity
