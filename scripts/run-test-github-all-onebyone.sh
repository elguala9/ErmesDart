#!/bin/sh
# Like run-test-github-all.sh, but dispatches EACH scenario onto its OWN
# per-scenario GitHub Actions workflow (.github/workflows/nat-<scenario>.yml)
# instead of the single shared nat-test.yml. Each scenario then shows up as its
# own Action (its own name + badge + history) in the Actions sidebar, so one
# failing scenario is isolated and does not taint the others.
#
# Mechanism: the only difference from run-test-github-all.sh is that this script
# exports WORKFLOW=nat-<scenario>.yml before invoking each leaf driver. The leaf
# drivers and lib/github-nat-driver.sh are UNCHANGED — the lib already honours
# `: "${WORKFLOW:=nat-test.yml}"`, so the env value set here wins per scenario.
#
# Still SEQUENTIAL on purpose: every scenario shares the throwaway relay
# identities and the workflows share one concurrency group, so they must not
# overlap. The driver blocks until each runner job completes before the next
# dispatches.
#
# Usage (from the repo, in a terminal):
#   sh scripts/run-test-github-all-onebyone.sh                  # all scenarios
#   sh scripts/run-test-github-all-onebyone.sh encrypted rekey  # only the listed
#
# Env:
#   LOG_DIR   where per-scenario logs go (default: $TMPDIR/ermes-github-tests)
#   plus every override honoured by lib/github-nat-driver.sh (TIMEOUT_MINUTES,
#   ERMES_NAT_REF, FLAP_CYCLES, ...).
#
# Prereq: the per-scenario workflow files must exist on the target ref (push the
# branch first). Works on Linux, macOS and Windows (Git Bash). Requires `gh`
# (authenticated) and the Dart SDK.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Same set/order as run-test-github-all.sh: P3 first (encrypted gates the rest),
# then the P1 reconnection family.
ALL="encrypted rekey graceful-reconnect peer-restart flap flap-storm long-outage"
SCENARIOS="${*:-$ALL}"

LOG_DIR="${LOG_DIR:-${TMPDIR:-/tmp}/ermes-github-tests}"
mkdir -p "$LOG_DIR"

passed=""
failed=""

for s in $SCENARIOS; do
  driver="$SCRIPT_DIR/run-test-github-$s.sh"
  workflow="nat-$s.yml"
  log="$LOG_DIR/$s.log"
  echo "======================================================================"
  echo ">>> Scenario: $s"
  echo "    driver:   $driver"
  echo "    workflow: $workflow"
  echo "    log:      $log"
  echo "======================================================================"

  if [ ! -f "$driver" ]; then
    echo "SKIP: no driver found for scenario '$s'." | tee "$log"
    failed="$failed $s"
    continue
  fi

  # tee shows live output AND keeps the full log. POSIX sh has no PIPESTATUS, so
  # recover the driver's real exit code via a temp file. WORKFLOW is exported
  # only for this driver invocation, so each scenario dispatches its own
  # nat-<scenario>.yml while the leaf drivers stay untouched.
  rc_file="$LOG_DIR/.$s.rc"
  rm -f "$rc_file"
  { WORKFLOW="$workflow" sh "$driver"; echo $? >"$rc_file"; } 2>&1 | tee "$log"
  drc="$(cat "$rc_file" 2>/dev/null || echo 1)"
  rm -f "$rc_file"

  if [ "$drc" -eq 0 ]; then
    passed="$passed $s"
    echo ">>> $s: PASS"
  else
    failed="$failed $s"
    echo ">>> $s: FAIL"
  fi
  echo
done

echo "######################################################################"
echo "# SUMMARY"
echo "######################################################################"
echo "PASSED:${passed:- none}"
echo "FAILED:${failed:- none}"

if [ -n "$failed" ]; then
  echo
  echo "--- error tails for failed scenarios -------------------------------"
  for s in $failed; do
    log="$LOG_DIR/$s.log"
    echo
    echo ">>> $s  ($log)"
    if [ -f "$log" ]; then
      grep -E "RESULT: FAIL|Error|Exception|StateError|Timeout" "$log" \
        | tail -n 15 || tail -n 15 "$log"
    fi
  done
  echo
  echo "Confirm the peer-b (runner) verdicts on GitHub Actions too — each"
  echo "scenario is its own 'NAT — <scenario>' workflow:"
  for s in $failed; do echo "  gh run list --workflow=nat-$s.yml"; done
  exit 1
fi

echo
echo "All scenarios passed locally. Confirm peer-b on GitHub Actions — each"
echo "scenario is its own 'NAT — <scenario>' workflow:"
for s in $SCENARIOS; do echo "  gh run list --workflow=nat-$s.yml"; done
exit 0
