#!/bin/sh
# P4 keepalive: idle the link for IDLE_DURATION with keepalive traffic only, then resume WITHOUT a full re-rendezvous (NAT mapping held).
#
# Dispatches peer-b (receiver) on a GitHub runner and runs peer-a (sender)
# locally with NAT_SCENARIO=keepalive, then reports the combined PASS/FAIL.
# Usage: sh scripts/run-test-github-keepalive.sh
set -eu

SCENARIO=keepalive
: "${TIMEOUT_MINUTES:=20}"
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
