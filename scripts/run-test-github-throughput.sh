#!/bin/sh
# P4 throughput: sustain TARGET_RATE msg/s for DURATION seconds over real NAT; reports achieved rate, p50/p99 latency and loss.
#
# Dispatches peer-b (receiver) on a GitHub runner and runs peer-a (sender)
# locally with NAT_SCENARIO=throughput, then reports the combined PASS/FAIL.
# Usage: sh scripts/run-test-github-throughput.sh
set -eu

SCENARIO=throughput
: "${TIMEOUT_MINUTES:=20}"
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
