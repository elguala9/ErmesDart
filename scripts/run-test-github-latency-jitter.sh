#!/bin/sh
# P5 latency-jitter: the runner peer-b runs behind 'tc netem delay DELAY_MS/JITTER_MS'; no false disconnect and no duplicate delivery.
#
# Dispatches peer-b (receiver) on a GitHub runner and runs peer-a (sender)
# locally with NAT_SCENARIO=latency-jitter, then reports the combined PASS/FAIL.
# Usage: sh scripts/run-test-github-latency-jitter.sh
set -eu

SCENARIO=latency-jitter
: "${TIMEOUT_MINUTES:=20}"
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
