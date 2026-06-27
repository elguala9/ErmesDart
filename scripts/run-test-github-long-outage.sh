#!/bin/sh
# P1 long-outage: the local peer breaks the link longer than the relay signal
# lifetime (~10 min) so the published signal expires, then restores; both sides
# republish a fresh signal and re-rendezvous. Long-running — burns CI minutes,
# so the survivor job timeout defaults to 30 min here.
#
# Cheaper smoke run (shorter than the real signal lifetime — not faithful):
#   LONG_OUTAGE_SECONDS=120 TIMEOUT_MINUTES=10 ./run-test-github-long-outage.sh
set -eu

SCENARIO=long-outage
: "${TIMEOUT_MINUTES:=30}"
if [ -n "${LONG_OUTAGE_SECONDS:-}" ]; then
  export LONG_OUTAGE_SECONDS
fi
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
