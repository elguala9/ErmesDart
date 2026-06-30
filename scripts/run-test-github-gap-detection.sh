#!/bin/sh
# P2 gap-detection: the local sender withholds targeted sequence numbers; the runner requests the exact missing IDs and the sender resends only those.
#
# Dispatches peer-b (receiver) on a GitHub runner and runs peer-a (sender)
# locally with NAT_SCENARIO=gap-detection, then reports the combined PASS/FAIL.
# Usage: sh scripts/run-test-github-gap-detection.sh
set -eu

SCENARIO=gap-detection
: "${TIMEOUT_MINUTES:=20}"
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
