#!/bin/sh
# Runs EVERY GitHub Actions NAT scenario in sequence and reports which failed.
#
# For each scenario it invokes the matching run-test-github-<scenario>.sh, which
# dispatches peer-b (responder) on a GitHub runner and runs peer-a (initiator)
# locally. The per-scenario PASS/FAIL is taken from that driver's own verdict
# line (the LOCAL peer-a result); confirm the peer-b side on GitHub Actions.
#
# Scenarios run one at a time on purpose: they share the throwaway relay
# identities and the workflow's concurrency group, so they must not overlap.
#
# Usage (from the repo, in a terminal):
#   sh scripts/run-test-github-all.sh                  # all scenarios
#   sh scripts/run-test-github-all.sh encrypted rekey  # only the listed ones
#
# Env:
#   LOG_DIR   where per-scenario logs go (default: $TMPDIR/ermes-github-tests)
#   plus every override honoured by lib/github-nat-driver.sh (TIMEOUT_MINUTES,
#   ERMES_NAT_REF, FLAP_CYCLES, ...).
#
# Heads-up: the full set is long (long-outage alone is >10 min). Pass a subset
# while iterating.
#
# Works on Linux, macOS and Windows (Git Bash). Requires `gh` (authenticated)
# and the Dart SDK.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Every scenario that has a run-test-github-<name>.sh driver. P3 first (the
# encrypted smoke test gates the rest), then the P1 reconnection family.
ALL="encrypted rekey graceful-reconnect peer-restart flap flap-storm long-outage"
SCENARIOS="${*:-$ALL}"

LOG_DIR="${LOG_DIR:-${TMPDIR:-/tmp}/ermes-github-tests}"
mkdir -p "$LOG_DIR"

passed=""
failed=""

for s in $SCENARIOS; do
  driver="$SCRIPT_DIR/run-test-github-$s.sh"
  log="$LOG_DIR/$s.log"
  echo "======================================================================"
  echo ">>> Scenario: $s"
  echo "    driver: $driver"
  echo "    log:    $log"
  echo "======================================================================"

  if [ ! -f "$driver" ]; then
    echo "SKIP: no driver found for scenario '$s'." | tee "$log"
    failed="$failed $s"
    continue
  fi

  # tee shows live output AND keeps the full log. POSIX sh has no PIPESTATUS,
  # so the verdict is read back from the driver's own "RESULT:" line, which
  # report_and_exit always prints.
  sh "$driver" 2>&1 | tee "$log"

  if grep -q "RESULT: PASS" "$log"; then
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
  echo "Confirm the peer-b (runner) verdicts on GitHub Actions too:"
  echo "  gh run list --workflow=nat-test.yml"
  exit 1
fi

echo
echo "All scenarios passed locally. Confirm peer-b on GitHub Actions:"
echo "  gh run list --workflow=nat-test.yml"
exit 0
