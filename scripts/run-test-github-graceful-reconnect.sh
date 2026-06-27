#!/bin/sh
# P1 graceful-reconnect: the local peer cleanly tears the link down
# (disconnectNow + close), both sides re-rendezvous and resume with no loss.
# Runs peer-b (survivor) on GitHub Actions and peer-a locally.
set -eu

SCENARIO=graceful-reconnect
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
