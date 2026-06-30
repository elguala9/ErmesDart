#!/bin/sh
# P2 fragmented-break: the local sender transmits a multi-MB payload and breaks the link mid-stream; the runner must reassemble it byte-for-byte (checksum match) after resume. Override size with FRAGMENT_BYTES.
#
# Dispatches peer-b (receiver) on a GitHub runner and runs peer-a (sender)
# locally with NAT_SCENARIO=fragmented-break, then reports the combined PASS/FAIL.
# Usage: sh scripts/run-test-github-fragmented-break.sh
set -eu

SCENARIO=fragmented-break
: "${TIMEOUT_MINUTES:=20}"
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
