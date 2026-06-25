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
# Run it FROM your terminal (not by double-clicking) so the output stays
# inline and Ctrl+C stops the run:
#   sh run-nat-test.sh a           # this machine is the initiator (Alice)
#   sh run-nat-test.sh b           # this machine is the responder (Bob)
#
# On Windows: launch it inside Git Bash, or from PowerShell/Windows Terminal
# as `bash run-nat-test.sh b` — double-clicking the .sh opens a separate
# Git Bash window instead of running in the terminal you are looking at.
#
# Press Ctrl+C at any time to stop: the container is given a name and torn
# down cleanly (it runs with --init so signals reach the test process).
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

OS="$(uname -s)"
case "$OS" in
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

# Request a pseudo-TTY only on a real Unix terminal: it streams the container
# output live into THIS terminal and lets Ctrl+C reach the process group.
# Skipped when piped (curl | sh, no TTY) and on Windows/MSYS, where a native
# docker.exe with -t misbehaves; output still streams there without it.
TTY_ARG=""
case "$OS" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *) [ -t 1 ] && TTY_ARG="-t" ;;
esac

# Name the container so a Ctrl+C in this shell can stop it explicitly, as a
# backstop to docker's own signal forwarding — never leaves an orphan behind.
CONTAINER="ermes-nat-$ROLE-$$"
trap '"$ENGINE" stop "$CONTAINER" >/dev/null 2>&1 || true' INT TERM

RC=0
# --init runs an init process (tini) as PID 1 inside the container; without it
# the test binary is PID 1 and the kernel drops SIGINT/SIGTERM there, so Ctrl+C
# cannot stop the run. --rm removes the container on exit.
# shellcheck disable=SC2086  # TTY_ARG / ENV_ARGS are deliberate word-split lists
"$ENGINE" run --rm --init --name "$CONTAINER" --network host \
  $TTY_ARG $ENV_ARGS "$IMAGE" "$ROLE" || RC=$?
trap - INT TERM

echo
if [ "$RC" -eq 0 ]; then
  echo "RESULT: PASS — full handshake + message sequence completed (exit 0)."
else
  echo "RESULT: FAIL (exit $RC) — see the log above for the failing step."
  echo "Reminder: symmetric NAT / CGNAT (typical 4G/5G) is EXPECTED to fail"
  echo "until the protocol gains TURN; that outcome is still a valid finding."
fi
exit "$RC"
