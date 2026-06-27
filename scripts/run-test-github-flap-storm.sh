#!/bin/sh
# P1 flap-storm: the local peer breaks and restores the link FLAP_CYCLES times
# (each break > linkSilenceThreshold so it genuinely reconnects). Every cycle
# must reconnect and no connection must leak. Runs peer-b on Actions, peer-a
# locally.
#
# Override the cycle count: FLAP_CYCLES=5 ./run-test-github-flap-storm.sh
set -eu

SCENARIO=flap-storm
: "${FLAP_CYCLES:=3}"
export FLAP_CYCLES
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
