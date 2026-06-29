# Shared helper for the P1 GitHub-Actions reconnection tests.
#
# Sourced (not executed) by the run-test-github-<scenario>.sh wrappers. It
# dispatches the SURVIVOR (peer-b) job on GitHub Actions and runs the
# break-producing INITIATOR (peer-a) locally with NAT_SCENARIO set, then
# reports the local peer's PASS/FAIL. The break itself is produced in-process
# by the Dart engine, so this stays pure POSIX sh and runs unchanged in Git
# Bash on Windows and in sh on Linux/macOS — no firewall rules, no root.
#
# The peer-b verdict lives in its own Actions job (download peer-b-log or read
# the run on GitHub); this script only governs the local peer-a side.
#
# Override any default via the environment, e.g.:
#   NOSTR_ALICE_PRIVKEY=... TIMEOUT_MINUTES=30 ./run-test-github-long-outage.sh

# Defaults mirror .github/workflows/nat-test.yml so a local run pairs with the
# runner out of the box.
: "${ALICE_PUBKEY:=b92ad53e9350444f5572b4ffdc51a9839161729b0f5a62e68a3694c78d3dc4c5}"
: "${BOB_PUBKEY:=40f72d5b56f8fcda629d4fd9e046038480cc71aaee01b3a2fc524aba6803dcac}"
: "${NOSTR_ALICE_PRIVKEY:=baeed075852a757626e2bae3220c915ec43bcdc81343f83b0f50e3a933063d6c}"
: "${STUN_HOST:=stun.l.google.com}"
: "${STUN_PORT:=19302}"
: "${NOSTR_RELAYS:=wss://nos.lol,wss://relay.damus.io,wss://nostr-pub.wellorder.net,wss://relay.primal.net}"
: "${WORKFLOW:=nat-test.yml}"
: "${TIMEOUT_MINUTES:=15}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PEER_A_SRC="$REPO_ROOT/packages/ermes_test_docker/bin/nat_peer_a.dart"
PEER_A_BIN="$REPO_ROOT/peer_a_local"
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*) PEER_A_BIN="$PEER_A_BIN.exe" ;;
esac

# Identity / rendezvous environment shared by every local peer-a launch. These
# are exported so the compiled binary inherits them; scenario knobs the wrapper
# exports (FLAP_CYCLES, LONG_OUTAGE_SECONDS, ...) are inherited the same way.
export ALICE_PUBKEY BOB_PUBKEY STUN_HOST STUN_PORT NOSTR_RELAYS
export NOSTR_PRIVKEY="$NOSTR_ALICE_PRIVKEY"
export NOSTR_PUBKEY="$ALICE_PUBKEY"
export ACCOUNT_ID="$ALICE_PUBKEY"

# Dispatch the survivor job on Actions. Best-effort: if `gh` is missing or the
# dispatch fails, print the exact command so the user can start peer-b by hand.
trigger_runner() {
  scenario="$1"
  if ! command -v gh >/dev/null 2>&1; then
    echo "WARNING: 'gh' CLI not found — NOT triggering the runner job."
    echo "         Start peer-b manually, then re-run this script:"
    echo "         gh workflow run $WORKFLOW -f side=b-only -f scenario=$scenario -f timeout_minutes=$TIMEOUT_MINUTES"
    return 0
  fi
  # The dispatched workflow must EXIST on the target ref, so run it against the
  # current branch (override with ERMES_NAT_REF). Push this branch first.
  ref="${ERMES_NAT_REF:-$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)}"
  echo "Dispatching peer-b (survivor) on Actions: ref=$ref scenario=$scenario timeout=${TIMEOUT_MINUTES}m"
  gh workflow run "$WORKFLOW" --ref "$ref" \
    -f side=b-only \
    -f scenario="$scenario" \
    -f timeout_minutes="$TIMEOUT_MINUTES" ||
    echo "WARNING: 'gh workflow run' failed; start peer-b manually (see above)."
}

# Compile peer-a once to a single native process so the peer-restart driver can
# hard-kill it cleanly (a `dart run` launcher can leave a child VM behind).
compile_local() {
  echo "Resolving local dependencies ..."
  (cd "$REPO_ROOT" && dart pub get >/dev/null)
  # Kill any stale peer-a still holding the binary open. A Ctrl-C of the run or
  # a peer-restart scenario can orphan the native process; on Windows that locks
  # the .exe (errno 32) and the next `dart compile exe` fails to overwrite it.
  case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*) taskkill //F //IM peer_a_local.exe >/dev/null 2>&1 || true ;;
    *) pkill -f peer_a_local >/dev/null 2>&1 || true ;;
  esac
  echo "Compiling local peer-a -> $PEER_A_BIN ..."
  (cd "$REPO_ROOT" && dart compile exe "$PEER_A_SRC" -o "$PEER_A_BIN")
}

# Run the local initiator to completion. Returns the binary's exit code.
run_local() {
  scenario="$1"
  echo "Running local peer-a (initiator) scenario=$scenario ..."
  NAT_SCENARIO="$scenario" "$PEER_A_BIN"
}

# peer-restart: run peer-a, hard-kill it after RESTART_AFTER seconds, then
# relaunch with the SAME identity. The survivor on the runner must detect the
# drop and the restarted local peer must rejoin. Returns the relaunch exit code.
run_local_restart() {
  scenario="$1"
  : "${RESTART_AFTER:=20}"
  echo "Running local peer-a; hard-kill after ${RESTART_AFTER}s, then relaunch ..."
  NAT_SCENARIO="$scenario" "$PEER_A_BIN" &
  pid=$!
  sleep "$RESTART_AFTER"
  echo "Hard-killing local peer-a (pid $pid) ..."
  kill -9 "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  sleep 2
  echo "Relaunching local peer-a with the same identity ..."
  NAT_SCENARIO="$scenario" "$PEER_A_BIN"
}

# Print the final verdict from the local peer-a exit code and exit with it.
report_and_exit() {
  rc="$1"
  scenario="$2"
  echo
  if [ "$rc" -eq 0 ]; then
    echo "RESULT: PASS — local peer-a ($scenario) completed (exit 0)."
    echo "Check the peer-b (survivor) job on GitHub Actions for its verdict."
  else
    echo "RESULT: FAIL (exit $rc) — local peer-a ($scenario); see the log above."
  fi
  exit "$rc"
}
