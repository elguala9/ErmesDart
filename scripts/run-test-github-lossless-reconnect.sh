#!/bin/sh
# P2 lossless-reconnect: the local sender keeps emitting sequenced data straight through an in-process outage; the runner receiver must end with every sequence number, in order (retransmission fills the hole).
#
# Dispatches peer-b (receiver) on a GitHub runner and runs peer-a (sender)
# locally with NAT_SCENARIO=lossless-reconnect, then reports the combined PASS/FAIL.
# Usage: sh scripts/run-test-github-lossless-reconnect.sh
set -eu

SCENARIO=lossless-reconnect
: "${TIMEOUT_MINUTES:=20}"
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
