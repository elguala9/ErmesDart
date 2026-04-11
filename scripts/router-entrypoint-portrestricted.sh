#!/bin/sh
set -e

# Port-Restricted Cone NAT
# ================================================
# Characteristics:
# - Static port mapping (same external port for each internal port)
# - Inbound filtering by SOURCE ADDRESS AND SOURCE PORT
# - Most restrictive of the "Cone" NATs
# - Allows return traffic ONLY from the exact (IP, PORT) pair
#   that was used in the outbound connection
# - STUN is problematic: discovered address may not work if
#   connecting peer uses different port than expected
#
# Implementation: Stateful firewall with conntrack at quadruplet level
# (conntrack tracks src_ip, src_port, dst_ip, dst_port)
# Blocks any NEW inbound that doesn't match the established flow

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

# Port-Restricted filtering: Strict conntrack
# Only allow return traffic that matches the established flow
# (both address AND port must match the originating connection)
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth0 -m conntrack --ctstate NEW -j DROP

# Drop any packet that doesn't match state (extra restrictive)
iptables -A FORWARD -j DROP

echo "[Router] Port-Restricted Cone NAT rules installed"
echo "[Router] Zone-A (172.30.10.0/24) and Zone-B (172.30.20.0/24) masqueraded via 172.30.0.1"
echo "[Router] Port mapping: STATIC (same external port for all destinations)"
echo "[Router] Inbound filtering: BY SOURCE ADDRESS+PORT (strict quadruplet matching)"
echo "[Router] Expected: STUN mostly fails, P2P connections likely fail unless port aligns"

# Keep container alive
exec sleep infinity
