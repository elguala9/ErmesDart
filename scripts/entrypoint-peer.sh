#!/bin/sh
# Entrypoint script for ErmesDart peer node
# Applies optional network latency via tc netem before starting the peer

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
