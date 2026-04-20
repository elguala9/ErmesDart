#!/bin/sh
set -e

# Address-Restricted Cone NAT Router (single-zone)
# ====================================
# Static port mapping, inbound filtered by source address.
# Only allows return traffic from IPs the internal host has contacted.

apk add --no-cache iptables iproute2 > /dev/null 2>&1

ZONE_NET=$(echo "$ZONE_SUBNET" | cut -d'.' -f1-3)
PUBLIC_IF=""
ZONE_IF=""

for iface in $(ls /sys/class/net/ | grep -v lo); do
  IP=$(ip -o -4 addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d'/' -f1)
  [ -z "$IP" ] && continue
  case "$IP" in
    ${ZONE_NET}.*) ZONE_IF="$iface" ;;
    *) PUBLIC_IF="$iface" ;;
  esac
done

echo "[Router] Address-Restricted NAT - Zone: $ZONE_SUBNET"
echo "[Router]   Public interface: $PUBLIC_IF"
echo "[Router]   Zone interface:   $ZONE_IF"

iptables -t nat -F 2>/dev/null || true
iptables -t nat -X 2>/dev/null || true
iptables -F 2>/dev/null || true
iptables -X 2>/dev/null || true

# Static port mapping
iptables -t nat -A POSTROUTING -s "$ZONE_SUBNET" -o "$PUBLIC_IF" -j MASQUERADE

# Address-Restricted: allow established return traffic + outbound from zone
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i "$ZONE_IF" -o "$PUBLIC_IF" -j ACCEPT
iptables -A FORWARD -i "$PUBLIC_IF" -j DROP

echo "[Router] Rules installed. Port mapping: STATIC, Inbound: ADDRESS-RESTRICTED"

exec sleep infinity
