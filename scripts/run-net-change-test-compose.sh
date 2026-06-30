#!/bin/sh
# Network-change (NAT mapping swap) test driver.
#
# Brings up the two NAT-test peers via docker-compose.net-change.yml, waits
# until the exchange is live, then forces a network change on the moving peer
# (peer-b) and verifies the core re-rendezvous and the exchange resumes.
#
# Compose owns the START state (netA + peers); THIS script owns the CHANGE:
#   1. ensure the swap-destination network netB exists,
#   2. disconnect peer-b from netA, pause, connect it to netB
#      (a real handoff: the old source mapping dies, a new one appears),
#   3. flush the stale UDP conntrack flow so the kernel cannot keep routing
#      the dead hole-punched mapping,
#   4. wait for peer-b to exit and report PASS/FAIL from its exit code.
#
# REQUIRES a native Linux host (or WSL2): `conntrack` and the bridge swap need
# real netfilter. Under Docker/Podman Desktop the VM's own NAT layer masks the
# public-mapping change, so the run is not faithful (it still executes).
#
# Usage:
#   sh run-net-change-test-compose.sh            # run the full test
#   sh run-net-change-test-compose.sh --init     # pull image + (re)create networks, then run
#
# Press Ctrl+C at any time: the compose project is torn down cleanly.
#
# Env overrides:
#   ERMES_NAT_IMAGE   image to run (default quay.io/elguala/ermes-nat-test:latest)
#   ERMES_NAT_ENGINE  force engine: docker | podman (default: auto-detect)
#   READY_MARKER      log line in peer-b that means "exchange is live"
#                     (default "STEADY EXCHANGE LIVE;", printed by the
#                     network-change responder once the heartbeat is steady)
#   READY_TIMEOUT     seconds to wait for READY_MARKER before giving up (default 360)
#   BREAK_PAUSE       seconds peer-b stays on NO network, simulating the dead
#                     interval of a real handoff (default 3)
set -eu

# --- locate compose file relative to this script -----------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/../packages/ermes_test_pc/docker/docker-compose.net-change.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
  echo "ERROR: compose file not found at $COMPOSE_FILE" >&2
  exit 1
fi

# Fixed names/subnets — must match docker-compose.net-change.yml.
PEER_B="ermes-net-change-peer-b"
NET_A="ermes-netA"
NET_B="ermes-netB"
NET_B_SUBNET="172.31.0.0/16"

IMAGE="${ERMES_NAT_IMAGE:-quay.io/elguala/ermes-nat-test:latest}"
READY_MARKER="${READY_MARKER:-STEADY EXCHANGE LIVE;}"
READY_TIMEOUT="${READY_TIMEOUT:-360}"
BREAK_PAUSE="${BREAK_PAUSE:-3}"

INIT=0
[ "${1:-}" = "--init" ] && INIT=1

# --- pick a container engine: docker or podman -------------------------------
ENGINE="${ERMES_NAT_ENGINE:-}"
if [ -z "$ENGINE" ]; then
  if command -v docker >/dev/null 2>&1; then
    ENGINE=docker
  elif command -v podman >/dev/null 2>&1; then
    ENGINE=podman
  else
    echo "ERROR: neither docker nor podman found. Install one and retry." >&2
    exit 1
  fi
fi
if ! "$ENGINE" info >/dev/null 2>&1; then
  echo "ERROR: $ENGINE is installed but not running." >&2
  exit 1
fi

# Resolve the compose front-end: `docker compose` (v2 plugin),
# `podman compose`, or standalone `podman-compose`.
compose() {
  case "$ENGINE" in
    docker) "$ENGINE" compose -f "$COMPOSE_FILE" "$@" ;;
    podman)
      if "$ENGINE" compose version >/dev/null 2>&1; then
        "$ENGINE" compose -f "$COMPOSE_FILE" "$@"
      elif command -v podman-compose >/dev/null 2>&1; then
        podman-compose -f "$COMPOSE_FILE" "$@"
      else
        echo "ERROR: no compose front-end for podman (install podman-compose" >&2
        echo "       or the Docker Compose v2 plugin)." >&2
        exit 1
      fi
      ;;
  esac
}

# --- platform fidelity warning -----------------------------------------------
case "$(uname -s)" in
  Linux) ;;
  *)
    echo "WARNING: not a native Linux host. Under Docker/Podman Desktop the VM" >&2
    echo "         adds a NAT layer that masks the mapping change; PASS/FAIL"  >&2
    echo "         here is NOT a faithful result." >&2
    ;;
esac
if ! command -v conntrack >/dev/null 2>&1; then
  echo "WARNING: 'conntrack' not found; the stale UDP flow cannot be flushed." >&2
  echo "         Install conntrack-tools for a faithful network-change test."  >&2
fi

# --- teardown on exit / Ctrl+C -----------------------------------------------
cleanup() {
  echo
  echo "Tearing down compose project..."
  compose down -v >/dev/null 2>&1 || true
}
trap 'cleanup' INT TERM EXIT

# --- optional one-time setup -------------------------------------------------
if [ "$INIT" -eq 1 ]; then
  echo "Pulling $IMAGE ..."
  "$ENGINE" pull "$IMAGE" 2>&1 || echo "WARN: pull failed; using local copy."
  echo "Recreating network $NET_B ($NET_B_SUBNET)..."
  "$ENGINE" network rm "$NET_B" >/dev/null 2>&1 || true
fi

# netB is the swap destination (owned by this script, not by compose).
if ! "$ENGINE" network inspect "$NET_B" >/dev/null 2>&1; then
  echo "Creating swap-destination network $NET_B ($NET_B_SUBNET)..."
  "$ENGINE" network create --subnet "$NET_B_SUBNET" "$NET_B" >/dev/null
fi

# --- bring up the start state ------------------------------------------------
echo "Bringing up peers on $NET_A (compose)..."
compose up -d

# --- wait until the exchange is live -----------------------------------------
echo "Waiting up to ${READY_TIMEOUT}s for peer-b marker \"$READY_MARKER\"..."
elapsed=0
while [ "$elapsed" -lt "$READY_TIMEOUT" ]; do
  if "$ENGINE" logs "$PEER_B" 2>&1 | grep -q "$READY_MARKER"; then
    break
  fi
  # bail out early if peer-b already died (config error, failed rendezvous)
  if ! "$ENGINE" inspect -f '{{.State.Running}}' "$PEER_B" 2>/dev/null \
       | grep -q true; then
    echo "ERROR: peer-b exited before the exchange went live. Logs:" >&2
    "$ENGINE" logs "$PEER_B" 2>&1 | tail -n 30 >&2
    exit 1
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done
if [ "$elapsed" -ge "$READY_TIMEOUT" ]; then
  echo "ERROR: timed out waiting for \"$READY_MARKER\" in peer-b logs." >&2
  exit 1
fi
echo "Exchange is live."

# --- THE NETWORK CHANGE ------------------------------------------------------
# Capture peer-b's current (netA) IP so we can target the stale flow precisely.
OLD_IP="$("$ENGINE" inspect \
  -f "{{(index .NetworkSettings.Networks \"$NET_A\").IPAddress}}" \
  "$PEER_B" 2>/dev/null || true)"
echo "peer-b old IP on $NET_A: ${OLD_IP:-<unknown>}"

echo "Disconnecting peer-b from $NET_A (link goes dark for ${BREAK_PAUSE}s)..."
"$ENGINE" network disconnect "$NET_A" "$PEER_B"
sleep "$BREAK_PAUSE"

echo "Flushing stale UDP conntrack flow..."
if command -v conntrack >/dev/null 2>&1; then
  if [ -n "$OLD_IP" ]; then
    sudo conntrack -D -s "$OLD_IP" >/dev/null 2>&1 || true
  fi
  sudo conntrack -D -p udp >/dev/null 2>&1 || true
fi

echo "Connecting peer-b to $NET_B (new source mapping)..."
"$ENGINE" network connect "$NET_B" "$PEER_B"
NEW_IP="$("$ENGINE" inspect \
  -f "{{(index .NetworkSettings.Networks \"$NET_B\").IPAddress}}" \
  "$PEER_B" 2>/dev/null || true)"
echo "peer-b new IP on $NET_B: ${NEW_IP:-<unknown>}"

# --- wait for the verdict ----------------------------------------------------
echo "Network changed; waiting for peer-b to verify the exchange resumed..."
RC=0
"$ENGINE" wait "$PEER_B" >/tmp/ermes-net-change-rc 2>/dev/null || RC=$?
[ "$RC" -eq 0 ] && RC="$(cat /tmp/ermes-net-change-rc 2>/dev/null || echo 0)"

echo "--- peer-b log tail ---"
"$ENGINE" logs "$PEER_B" 2>&1 | tail -n 20

echo
if [ "$RC" -eq 0 ]; then
  echo "RESULT: PASS — peer-b re-rendezvoused after the network change."
else
  echo "RESULT: FAIL (exit $RC) — exchange did not resume; see the log above."
fi
exit "$RC"
