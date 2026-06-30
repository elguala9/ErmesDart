#!/bin/sh
# P5 lossy: the runner peer-b runs behind 'tc netem loss LOSS_PCT%'; delivery must still complete via retransmission (gaps=0).
#
# Dispatches peer-b (receiver) on a GitHub runner and runs peer-a (sender)
# locally with NAT_SCENARIO=lossy, then reports the combined PASS/FAIL.
# Usage: sh scripts/run-test-github-lossy.sh
set -eu

SCENARIO=lossy
: "${TIMEOUT_MINUTES:=20}"
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
