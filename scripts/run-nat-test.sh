#!/bin/sh
# Download-and-go runner for the Ermes NAT-traversal test.
#
# Pulls the published test image from Quay.io, runs ONE peer role on this
# machine, and prints PASS/FAIL. Run role `a` on one machine/network and
# role `b` on another while both are running (the rendezvous loop absorbs
# start-order skew).
#
# Works on Linux, macOS and Windows (Git Bash or WSL). No repo clone, no
# Dart SDK; only a container engine — Docker or Podman, auto-detected.
#
# Usage:
#   ./run-nat-test.sh a            # this machine is the initiator (Alice)
#   ./run-nat-test.sh b            # this machine is the responder (Bob)
#
# Or straight from GitHub without downloading anything first:
#   curl -fsSL https://raw.githubusercontent.com/elguala9/ErmesDart/master/scripts/run-nat-test.sh | sh -s -- a
#
# Override the image (e.g. your own Quay.io namespace or a pinned tag):
#   ERMES_NAT_IMAGE=quay.io/mynamespace/ermes-nat-test:abc123 ./run-nat-test.sh b
#
# Any peer env var (NOSTR_*, STUN_*, SHSP_PORT, ...) set in the environment
# is forwarded into the container and overrides the built-in defaults.
set -eu

IMAGE="${ERMES_NAT_IMAGE:-quay.io/elguala/ermes-nat-test:latest}"
ROLE="${1:-}"

case "$ROLE" in
  a|A|alice) ROLE=a ;;
  b|B|bob)   ROLE=b ;;
  *)
    echo "Usage: $0 {a|b}" >&2
    echo "  a = initiator (Alice) on one machine, b = responder (Bob) on the other." >&2
    exit 2
    ;;
esac

# Pick a container engine: docker or podman, both work identically here.
# Force one with ERMES_NAT_ENGINE=podman (or docker).
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
  echo "ERROR: $ENGINE is installed but not running (start Docker Desktop" >&2
  echo "       or 'podman machine start')." >&2
  exit 1
fi

case "$(uname -s)" in
  Linux) ;;
  *)
    echo "NOTE: on Docker Desktop (Windows/macOS) the container runs inside a"
    echo "      VM, which adds an extra NAT layer to the path under test. The"
    echo "      test still runs, but a native Linux host gives a cleaner result."
    ;;
esac

echo "Pulling $IMAGE (engine: $ENGINE) ..."
if ! "$ENGINE" pull "$IMAGE"; then
  echo "WARN: pull failed; trying a locally cached copy." >&2
fi

# Forward any peer configuration the caller exported, so the same script
# also serves custom identities/relays. Unset vars fall back to the
# image's built-in public test defaults.
ENV_ARGS=""
for v in NOSTR_PUBKEY NOSTR_PRIVKEY ALICE_PUBKEY BOB_PUBKEY ACCOUNT_ID \
         STUN_HOST STUN_PORT NOSTR_RELAYS SHSP_PORT; do
  if eval "[ -n \"\${$v:-}\" ]"; then
    ENV_ARGS="$ENV_ARGS -e $v"
  fi
done

echo "Starting peer '$ROLE' (leave it running until the other side finishes)..."
RC=0
# shellcheck disable=SC2086  # ENV_ARGS is a deliberate word-split list
"$ENGINE" run --rm --network host $ENV_ARGS "$IMAGE" "$ROLE" || RC=$?

echo
if [ "$RC" -eq 0 ]; then
  echo "RESULT: PASS — full handshake + message sequence completed (exit 0)."
else
  echo "RESULT: FAIL (exit $RC) — see the log above for the failing step."
  echo "Reminder: symmetric NAT / CGNAT (typical 4G/5G) is EXPECTED to fail"
  echo "until the protocol gains TURN; that outcome is still a valid finding."
fi
exit "$RC"
