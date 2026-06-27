#!/bin/sh
# P1 flap (sub-threshold): the local peer pauses its data path for less than
# linkSilenceThreshold (8 s); the connection must NOT be torn down and no
# reconnect must be triggered. Runs peer-b on Actions, peer-a locally.
set -eu

SCENARIO=flap
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
