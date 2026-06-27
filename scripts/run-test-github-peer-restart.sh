#!/bin/sh
# P1 peer-restart: the local peer is hard-killed mid-exchange and relaunched
# with the SAME identity. The survivor (peer-b on Actions) must detect the drop
# and the restarted local peer must rejoin and resume. The survivor owns the
# verdict and prints the rejoinTimeMs metric in its own job log.
#
# Override the time before the kill: RESTART_AFTER=30 ./run-test-github-peer-restart.sh
set -eu

SCENARIO=peer-restart
: "${TIMEOUT_MINUTES:=20}"
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local_restart "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
