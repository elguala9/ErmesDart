#!/bin/sh
# GitHub Actions driver — NAT_SCENARIO=encrypted (P3 smoke test).
#
# Runs the default encrypted exchange end to end with peer-B (responder) on a
# GitHub runner and peer-A (initiator) locally: a real ECDH handshake over the
# punched link, then an encrypted burst. This is the FIRST scenario to run — it
# proves local<->Azure UDP hole-punch + ECDH/AES before any harder scenario.
#
# Usage (from the repo, in a terminal):
#   sh scripts/run-test-github-encrypted.sh
#
# Works on Linux, macOS and Windows (Git Bash). Requires `gh` (authenticated)
# and the Dart SDK. See lib/github-nat-driver.sh for env overrides.
set -eu

SCENARIO=encrypted
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
