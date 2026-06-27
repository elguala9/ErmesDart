#!/bin/sh
# GitHub Actions driver — NAT_SCENARIO=rekey (P3).
#
# Rotates the symmetric key mid-session on a live encrypted heartbeat between
# peer-B (responder) on a GitHub runner and peer-A (initiator) locally, and
# verifies messages before and after the rotation decrypt with the right key —
# no dropped or undecryptable message at the boundary.
#
# Run `run-test-github-encrypted.sh` first: if the encrypted smoke test cannot
# rendezvous, rekey cannot either.
#
# Usage (from the repo, in a terminal):
#   sh scripts/run-test-github-rekey.sh
#
# Works on Linux, macOS and Windows (Git Bash). Requires `gh` (authenticated)
# and the Dart SDK. See lib/github-nat-driver.sh for env overrides.
set -eu

SCENARIO=rekey
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
