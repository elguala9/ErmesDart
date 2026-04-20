#!/bin/sh
# Entrypoint script for ErmesDart peer node
# Sets up default gateway (NAT router) and optional network latency before starting the peer

# Set up default gateway to route through the NAT router
if [ -n "$DEFAULT_GATEWAY" ]; then
  echo "[entrypoint] Setting default gateway: $DEFAULT_GATEWAY"
  # Remove Docker's default gateway and replace with our NAT router
  ip route del default 2>/dev/null || true
  ip route add default via "$DEFAULT_GATEWAY"
  echo "[entrypoint] Route table:"
  ip route
fi

# Apply network latency via tc netem if NETWORK_LATENCY_MS is set
if [ -n "$NETWORK_LATENCY_MS" ]; then
  JITTER=${NETWORK_JITTER_MS:-5}
  LOSS=${NETWORK_PACKET_LOSS_PERCENT:-0}
  echo "[entrypoint] Applying tc netem: delay=${NETWORK_LATENCY_MS}ms jitter=${JITTER}ms loss=${LOSS}%"
  tc qdisc add dev eth0 root netem \
    delay "${NETWORK_LATENCY_MS}ms" "${JITTER}ms" distribution normal \
    loss "${LOSS}%"
fi

# Execute the peer node binary
exec /app/peer_node
