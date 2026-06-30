#!/bin/sh
# Runs the P3 encryption-family GitHub Actions NAT scenarios in sequence and
# reports which failed. P3 covers the encrypted-link contract:
#
#   encrypted  ECDH + AES bring-up; the local<->Azure traversal smoke test
#   rekey      mid-session symmetric-key rotation over the encrypted link
#
# Thin wrapper over run-test-github-all.sh with the P3 subset, so the per-
# scenario verdict, sequencing and summary all come from that one driver.
#
# Usage (from the repo, in a terminal):
#   sh scripts/run-test-github-p3.sh             # all P3 scenarios
#   sh scripts/run-test-github-p3.sh encrypted   # only the listed one
#
# Env: every override honoured by run-test-github-all.sh / lib/github-nat-driver.sh
# (LOG_DIR, TIMEOUT_MINUTES, ERMES_NAT_REF, ...).
#
# Works on Linux, macOS and Windows (Git Bash). Requires `gh` (authenticated)
# and the Dart SDK.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# encrypted first: it gates the family as the bring-up smoke test.
P3="encrypted rekey"

exec sh "$SCRIPT_DIR/run-test-github-all.sh" ${*:-$P3}
