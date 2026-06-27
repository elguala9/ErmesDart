#!/bin/sh
# GitHub Actions driver — NAT_SCENARIO=rekey (P3).
#
# Rotates the symmetric key mid-session on a live encrypted heartbeat between
# peer-B on a GitHub runner and peer-A on this machine, and verifies messages
# before and after the rotation decrypt with the right key — no dropped or
# undecryptable message at the boundary.
#
# Run `run-test-github-encrypted.sh` first: if the encrypted smoke test cannot
# rendezvous, rekey cannot either.
#
# Usage (from the repo, in a terminal):
#   sh scripts/run-test-github-rekey.sh
#
# Works on Linux, macOS and Windows (Git Bash). Requires `gh` (authenticated)
# and the Dart SDK. See lib-github-test.sh for env overrides.
set -eu

. "$(dirname "$0")/lib-github-test.sh"

run_github_scenario rekey
