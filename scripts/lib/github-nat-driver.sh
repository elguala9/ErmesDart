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

# peer-a is a native Windows console binary, and THE cardinal rule on Git Bash
# is: it must keep this terminal's stdio. Git Bash bridges a hidden console to
# a native console program ONLY while its output is a real tty; the moment you
# redirect or pipe that output (`>file`, `| tee`, `</dev/null`, `&` with
# redirection) the bridge is gone and Windows opens a SEPARATE console window
# for the binary. That popup is exactly the bug here — every previous attempt
# (`>>file`, then `| tee`) triggered it because both make stdout a non-tty.
#
# So on an interactive terminal we DO NOT capture: peer-a streams live into this
# same terminal, just like `dart compile` above — no window. The log file is
# only used on the non-interactive path (CI / piped via melos), where there is
# no tty to preserve anyway and capturing can no longer make things worse.
PEER_A_LOG="${PEER_A_LOG:-$REPO_ROOT/peer_a_local.log}"
PEER_A_RC="${PEER_A_RC:-$REPO_ROOT/.peer_a_local.rc}"

# Launch peer-a (NAT_SCENARIO read from the environment) and return ITS exit
# code. Interactive tty -> attached, no capture, no popup. Non-tty -> tee a log
# for diagnostics (POSIX sh has no PIPESTATUS / pipefail, so recover the real
# exit code via PEER_A_RC).
run_peer_a() {
  if [ -t 1 ]; then
    "$PEER_A_BIN"
  else
    rm -f "$PEER_A_RC"
    { "$PEER_A_BIN"; echo $? >"$PEER_A_RC"; } 2>&1 | tee -a "$PEER_A_LOG"
    rc="$(cat "$PEER_A_RC" 2>/dev/null || echo 1)"
    rm -f "$PEER_A_RC"
    return "$rc"
  fi
}

# Hard-kill the running peer-a by image/name on both platforms, so it works
# whether or not the shell holds a usable pid for the native process.
kill_peer_a() {
  case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*) taskkill //F //IM peer_a_local.exe >/dev/null 2>&1 || true ;;
    *) pkill -9 -f peer_a_local >/dev/null 2>&1 || true ;;
  esac
}

# Identity / rendezvous environment shared by every local peer-a launch. These
# are exported so the compiled binary inherits them; scenario knobs the wrapper
# exports (FLAP_CYCLES, LONG_OUTAGE_SECONDS, ...) are inherited the same way.
export ALICE_PUBKEY BOB_PUBKEY STUN_HOST STUN_PORT NOSTR_RELAYS
export NOSTR_PRIVKEY="$NOSTR_ALICE_PRIVKEY"
export NOSTR_PUBKEY="$ALICE_PUBKEY"
export ACCOUNT_ID="$ALICE_PUBKEY"

# Dispatch the survivor job on Actions and remember its run id in RUNNER_RUN_ID
# so report_and_exit can WAIT for it (keeps local peer-a and the runner in
# lockstep: the next scenario only dispatches after this run completes, so the
# shared concurrency group never cancels an in-flight run). Best-effort: if `gh`
# is missing the script still runs peer-a locally and just skips the wait.
trigger_runner() {
  scenario="$1"
  RUNNER_RUN_ID=""
  RUNNER_CONCLUSION=""
  if ! command -v gh >/dev/null 2>&1; then
    echo "WARNING: 'gh' CLI not found — NOT triggering the runner job."
    echo "         Start peer-b manually, then re-run this script:"
    echo "         gh workflow run $WORKFLOW -f side=b-only -f scenario=$scenario -f timeout_minutes=$TIMEOUT_MINUTES"
    return 0
  fi
  # The dispatched workflow must EXIST on the target ref, so run it against the
  # current branch (override with ERMES_NAT_REF). Push this branch first.
  ref="${ERMES_NAT_REF:-$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)}"

  # Newest run id BEFORE dispatch, so we can recognise the one we create
  # (`gh workflow run` does not print the id it triggers).
  prev_id="$(gh run list --workflow "$WORKFLOW" --branch "$ref" \
    --event workflow_dispatch --limit 1 --json databaseId \
    --jq '.[0].databaseId // empty' 2>/dev/null || echo "")"

  echo "Dispatching peer-b (survivor) on Actions: ref=$ref scenario=$scenario timeout=${TIMEOUT_MINUTES}m"
  if ! gh workflow run "$WORKFLOW" --ref "$ref" \
       -f side=b-only -f scenario="$scenario" -f timeout_minutes="$TIMEOUT_MINUTES"; then
    echo "WARNING: 'gh workflow run' failed; start peer-b manually (see above)."
    return 0
  fi

  echo "Waiting for the dispatched run to register ..."
  i=0
  while [ "$i" -lt 30 ]; do
    new_id="$(gh run list --workflow "$WORKFLOW" --branch "$ref" \
      --event workflow_dispatch --limit 1 --json databaseId \
      --jq '.[0].databaseId // empty' 2>/dev/null || echo "")"
    if [ -n "$new_id" ] && [ "$new_id" != "$prev_id" ]; then
      RUNNER_RUN_ID="$new_id"
      url="$(gh run view "$RUNNER_RUN_ID" --json url --jq .url 2>/dev/null || echo "")"
      echo "Runner run id: $RUNNER_RUN_ID  $url"
      return 0
    fi
    i=$((i + 1))
    sleep 2
  done
  echo "WARNING: could not determine the dispatched run id; will not wait for peer-b."
}

# Block until the dispatched runner job (RUNNER_RUN_ID) completes and record its
# conclusion in RUNNER_CONCLUSION. No-op when no run was tracked.
wait_for_runner() {
  [ -n "${RUNNER_RUN_ID:-}" ] || return 0
  command -v gh >/dev/null 2>&1 || return 0
  echo "Waiting for peer-b (runner) job $RUNNER_RUN_ID to finish ..."
  last=""
  while :; do
    status="$(gh run view "$RUNNER_RUN_ID" --json status --jq .status 2>/dev/null || echo "")"
    if [ -z "$status" ]; then
      echo "  (cannot read run status; not waiting further)"
      return 0
    fi
    if [ "$status" = completed ]; then
      break
    fi
    if [ "$status" != "$last" ]; then
      echo "  peer-b: $status ..."
      last="$status"
    fi
    sleep 15
  done
  RUNNER_CONCLUSION="$(gh run view "$RUNNER_RUN_ID" --json conclusion \
    --jq .conclusion 2>/dev/null || echo "")"
  echo "peer-b (runner) conclusion: ${RUNNER_CONCLUSION:-unknown}"
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
  export NAT_SCENARIO="$scenario"
  run_peer_a
}

# peer-restart: run peer-a, hard-kill it after RESTART_AFTER seconds, then
# relaunch with the SAME identity. The survivor on the runner must detect the
# drop and the restarted local peer must rejoin. Returns the relaunch exit code.
run_local_restart() {
  scenario="$1"
  : "${RESTART_AFTER:=20}"
  echo "Running local peer-a; hard-kill after ${RESTART_AFTER}s, then relaunch ..."
  export NAT_SCENARIO="$scenario"
  # Background WITHOUT any redirection so the child keeps this terminal on its
  # stdio (the winpty bridge still applies -> no popup). kill_peer_a targets it
  # by image name, so we do not depend on the backgrounded pid.
  "$PEER_A_BIN" &
  pid=$!
  sleep "$RESTART_AFTER"
  echo "Hard-killing local peer-a ..."
  kill_peer_a
  wait "$pid" 2>/dev/null || true
  sleep 2
  echo "Relaunching local peer-a with the same identity ..."
  run_peer_a
}

# Wait for the runner, then print a verdict combining BOTH sides — local peer-a
# (its exit code) and the runner peer-b (its conclusion) — and exit non-zero if
# either failed. The single authoritative `RESULT: PASS/FAIL — <scenario>` line
# is what run-test-github-all.sh and humans read.
report_and_exit() {
  rc="$1"
  scenario="$2"
  wait_for_runner
  echo

  if [ "$rc" -eq 0 ]; then
    echo "  peer-a (local):  PASS (exit 0)"
  else
    echo "  peer-a (local):  FAIL (exit $rc) — see the log above"
  fi

  runner_failed=0
  if [ -z "${RUNNER_RUN_ID:-}" ]; then
    echo "  peer-b (runner): not tracked — check GitHub Actions manually"
  else
    case "${RUNNER_CONCLUSION:-}" in
      success) echo "  peer-b (runner): PASS" ;;
      "")      echo "  peer-b (runner): UNKNOWN (verdict unavailable)" ;;
      *)       echo "  peer-b (runner): FAIL (${RUNNER_CONCLUSION})"; runner_failed=1 ;;
    esac
  fi

  echo
  if [ "$rc" -eq 0 ] && [ "$runner_failed" -eq 0 ]; then
    echo "RESULT: PASS — $scenario (peer-a + peer-b)"
    exit 0
  fi
  echo "RESULT: FAIL — $scenario (peer-a exit $rc, peer-b ${RUNNER_CONCLUSION:-untracked})"
  if [ "$rc" -ne 0 ]; then
    exit "$rc"
  fi
  exit 1
}
