#!/bin/sh
# nat-network-setup.sh
# ====================
# Runs as a privileged container with host networking to add iptables rules
# that allow cross-bridge forwarding between NAT test Docker networks.
#
# Docker's default bridge isolation drops packets forwarded between different
# bridge networks (DOCKER chain DROP rules). This script inserts ACCEPT rules
# in DOCKER-USER to bypass that isolation for our NAT test subnets.
#
# Required env vars:
#   PUBLIC_SUBNET_PREFIX  - e.g. "172.20.0"
#   ZONEA_SUBNET_PREFIX   - e.g. "172.20.10"
#   ZONEB_SUBNET_PREFIX   - e.g. "172.20.20"

set -e

apk add --no-cache iptables iproute2 > /dev/null 2>&1

find_bridge() {
  local prefix="$1"
  for br in $(ls /sys/class/net/ | grep -E '^br-'); do
    local ip
    ip=$(ip -4 addr show "$br" 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    case "$ip" in
      ${prefix}.*) echo "$br"; return ;;
    esac
  done
  echo ""
}

# Retry loop: bridges may not exist until Docker creates them
MAX_RETRIES=30
for attempt in $(seq 1 $MAX_RETRIES); do
  PUBLIC_BR=$(find_bridge "$PUBLIC_SUBNET_PREFIX")
  ZONEA_BR=$(find_bridge "$ZONEA_SUBNET_PREFIX")
  ZONEB_BR=$(find_bridge "$ZONEB_SUBNET_PREFIX")

  if [ -n "$PUBLIC_BR" ] && [ -n "$ZONEA_BR" ] && [ -n "$ZONEB_BR" ]; then
    break
  fi

  if [ "$attempt" -eq "$MAX_RETRIES" ]; then
    echo "[nat-network-setup] ERROR: Could not find all bridges after $MAX_RETRIES attempts"
    exit 1
  fi

  echo "[nat-network-setup] Waiting for bridges... (attempt $attempt/$MAX_RETRIES)"
  sleep 1
done

echo "[nat-network-setup] Public bridge: ${PUBLIC_BR:-NOT FOUND} (${PUBLIC_SUBNET_PREFIX}.0/24)"
echo "[nat-network-setup] Zone-A bridge: ${ZONEA_BR:-NOT FOUND} (${ZONEA_SUBNET_PREFIX}.0/24)"
echo "[nat-network-setup] Zone-B bridge: ${ZONEB_BR:-NOT FOUND} (${ZONEB_SUBNET_PREFIX}.0/24)"

if [ -z "$PUBLIC_BR" ] || [ -z "$ZONEA_BR" ] || [ -z "$ZONEB_BR" ]; then
  echo "[nat-network-setup] ERROR: Could not find all bridges. Available bridges:"
  for br in $(ls /sys/class/net/ | grep -E '^br-|^docker'); do
    ip=$(ip -4 addr show "$br" 2>/dev/null | grep 'inet ' | awk '{print $2}' || echo "no-ip")
    echo "  $br: $ip"
  done
  exit 1
fi

# Add ACCEPT rules for cross-bridge forwarding in DOCKER-USER
# DOCKER-USER is evaluated before DOCKER chain (which has the DROP rules)
for src in $PUBLIC_BR $ZONEA_BR $ZONEB_BR; do
  for dst in $PUBLIC_BR $ZONEA_BR $ZONEB_BR; do
    [ "$src" = "$dst" ] && continue
    # Check if rule already exists to avoid duplicates
    if ! iptables -C DOCKER-USER -i "$src" -o "$dst" -j ACCEPT 2>/dev/null; then
      iptables -I DOCKER-USER -i "$src" -o "$dst" -j ACCEPT
      echo "[nat-network-setup] ACCEPT: $src -> $dst"
    else
      echo "[nat-network-setup] Already exists: $src -> $dst"
    fi
  done
done

echo "[nat-network-setup] Cross-bridge forwarding enabled."
