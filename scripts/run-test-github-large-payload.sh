#!/bin/sh
# P4 large-payload: sweep SIZES (bytes); each reassembled payload must match its checksum, with bounded latency.
#
# Dispatches peer-b (receiver) on a GitHub runner and runs peer-a (sender)
# locally with NAT_SCENARIO=large-payload, then reports the combined PASS/FAIL.
# Usage: sh scripts/run-test-github-large-payload.sh
set -eu

SCENARIO=large-payload
: "${TIMEOUT_MINUTES:=20}"
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
