#!/bin/sh
set -e

# Full Cone NAT Router (single-zone)
# ========================================================
# Full Cone: static port mapping, no inbound filtering.
# Any external host can send to a mapped port and reach the internal host.
#
# Linux MASQUERADE only handles outbound + return traffic. For true Full Cone
# behavior (unsolicited inbound), we add DNAT rules for known SHSP ports.
# DNAT_MAPPINGS env var: "port1:ip1,port2:ip2,..."

apk add --no-cache iptables iproute2 tcpdump > /dev/null 2>&1

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

echo "[Router] Full Cone NAT - Zone: $ZONE_SUBNET"
echo "[Router]   Public interface: $PUBLIC_IF"
echo "[Router]   Zone interface:   $ZONE_IF"

iptables -t nat -F 2>/dev/null || true
iptables -t nat -X 2>/dev/null || true
iptables -F 2>/dev/null || true
iptables -X 2>/dev/null || true

# SNAT: masquerade outbound zone traffic (preserves source port when possible)
iptables -t nat -A POSTROUTING -s "$ZONE_SUBNET" -o "$PUBLIC_IF" -j MASQUERADE
# Hairpin NAT: masquerade zone traffic looping back through DNAT
iptables -t nat -A POSTROUTING -s "$ZONE_SUBNET" -o "$ZONE_IF" -j MASQUERADE

# DNAT: forward inbound traffic to internal hosts (Full Cone = unrestricted inbound)
if [ -n "$DNAT_MAPPINGS" ]; then
  IFS=','
  for mapping in $DNAT_MAPPINGS; do
    PORT=$(echo "$mapping" | cut -d':' -f1)
    DEST_IP=$(echo "$mapping" | cut -d':' -f2)
    iptables -t nat -A PREROUTING -p udp --dport "$PORT" -j DNAT --to-destination "$DEST_IP:$PORT"
    echo "[Router] DNAT: UDP $PORT -> $DEST_IP:$PORT"
  done
  unset IFS
fi

# Full Cone: NO FORWARD filtering - all traffic allowed
echo "[Router] Rules installed. Port mapping: STATIC, Inbound: UNRESTRICTED (Full Cone)"

exec sleep infinity
