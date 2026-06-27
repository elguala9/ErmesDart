#!/bin/sh
# Shared mechanics for the GitHub Actions encryption-test drivers.
#
# Each `run-test-github-<scenario>.sh` sources this file and calls
# `run_github_scenario <scenario>`. The helper:
#   1. dispatches .github/workflows/nat-test.yml with the responder (peer-b)
#      on a GitHub-hosted runner and the chosen NAT_SCENARIO,
#   2. runs the initiator (peer-a) locally with the SAME throwaway identities,
#      relays and STUN, and the same NAT_SCENARIO,
#   3. reports PASS/FAIL from the local initiator's exit code.
#
# The rendezvous loop in the binaries absorbs the start-order skew between the
# local process and the runner spinning up, so dispatch-then-run is enough.
#
# Works on Linux, macOS and Windows (Git Bash): pure POSIX sh + `gh` + `dart`.
#
# Env overrides (all optional):
#   ERMES_NAT_REF   git ref the workflow runs on (default: current branch)
#   ALICE_PUBKEY / BOB_PUBKEY / NAT_ALICE_PRIVKEY   shared identities
#   STUN_HOST / STUN_PORT / NOSTR_RELAYS            rendezvous infrastructure
#
# The identity/infra defaults MUST match .github/workflows/nat-test.yml so the
# local peer and the runner peer find each other on the same relay.

run_github_scenario() {
  SCENARIO="$1"
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  WORKFLOW="nat-test.yml"

  REF="${ERMES_NAT_REF:-$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)}"

  ALICE_PUBKEY="${ALICE_PUBKEY:-b92ad53e9350444f5572b4ffdc51a9839161729b0f5a62e68a3694c78d3dc4c5}"
  BOB_PUBKEY="${BOB_PUBKEY:-40f72d5b56f8fcda629d4fd9e046038480cc71aaee01b3a2fc524aba6803dcac}"
  ALICE_PRIVKEY="${NAT_ALICE_PRIVKEY:-baeed075852a757626e2bae3220c915ec43bcdc81343f83b0f50e3a933063d6c}"
  STUN_HOST="${STUN_HOST:-stun.l.google.com}"
  STUN_PORT="${STUN_PORT:-19302}"
  NOSTR_RELAYS="${NOSTR_RELAYS:-wss://nos.lol,wss://relay.damus.io,wss://nostr-pub.wellorder.net,wss://relay.primal.net}"

  if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: GitHub CLI (gh) not found. Install it and run 'gh auth login'." >&2
    exit 1
  fi
  if ! command -v dart >/dev/null 2>&1; then
    echo "ERROR: dart not found. Install the Dart SDK and retry." >&2
    exit 1
  fi

  echo "Dispatching $WORKFLOW (side=b-only, scenario=$SCENARIO) on ref '$REF'..."
  gh workflow run "$WORKFLOW" --ref "$REF" \
    -f side=b-only -f scenario="$SCENARIO"

  echo "Responder (peer-b) is spinning up on a GitHub runner. Follow it with:"
  echo "  gh run watch \$(gh run list --workflow=$WORKFLOW -L1 \\"
  echo "    --json databaseId -q '.[0].databaseId')"
  echo

  echo "Resolving local dependencies..."
  ( cd "$REPO_ROOT" && dart pub get >/dev/null )

  echo "Running local initiator (peer-a) for scenario '$SCENARIO'..."
  RC=0
  (
    cd "$REPO_ROOT"
    NAT_SCENARIO="$SCENARIO" \
    NOSTR_PUBKEY="$ALICE_PUBKEY" \
    NOSTR_PRIVKEY="$ALICE_PRIVKEY" \
    ACCOUNT_ID="$ALICE_PUBKEY" \
    ALICE_PUBKEY="$ALICE_PUBKEY" \
    BOB_PUBKEY="$BOB_PUBKEY" \
    STUN_HOST="$STUN_HOST" \
    STUN_PORT="$STUN_PORT" \
    NOSTR_RELAYS="$NOSTR_RELAYS" \
    dart run packages/ermes_test_docker/bin/nat_peer_a.dart
  ) || RC=$?

  echo
  if [ "$RC" -eq 0 ]; then
    echo "RESULT: PASS — local initiator completed scenario '$SCENARIO' (exit 0)."
    echo "Confirm the runner's peer-b also passed (RESULT: PASS in its log)."
  else
    echo "RESULT: FAIL (exit $RC) — see the log above and the runner's peer-b log."
  fi
  return "$RC"
}
