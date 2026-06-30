#!/bin/sh
# P5 mtu-edge: the runner peer-b interface MTU is constrained to MTU bytes; reassembly must stay correct with no oversized-datagram loss.
#
# Dispatches peer-b (receiver) on a GitHub runner and runs peer-a (sender)
# locally with NAT_SCENARIO=mtu-edge, then reports the combined PASS/FAIL.
# Usage: sh scripts/run-test-github-mtu-edge.sh
set -eu

SCENARIO=mtu-edge
: "${TIMEOUT_MINUTES:=20}"
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
