#!/bin/sh
# Runs the P2 message-reliability GitHub Actions NAT scenarios in sequence and
# reports which failed. The break / gap is always produced on the LOCAL sender:
#
#   lossless-reconnect  keep sending through an in-process outage; no gaps after
#   fragmented-break    multi-MB payload, link broken mid-stream; checksum match
#   gap-detection       withhold targeted seqs; receiver requests the exact IDs
#
# Thin wrapper over run-test-github-all.sh with the P2 subset.
#
# Usage:
#   sh scripts/run-test-github-p2.sh                     # all P2 scenarios
#   sh scripts/run-test-github-p2.sh gap-detection       # only the listed one
#
# Works on Linux, macOS and Windows (Git Bash). Requires `gh` and the Dart SDK.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
P2="lossless-reconnect fragmented-break gap-detection"
exec sh "$SCRIPT_DIR/run-test-github-all.sh" ${*:-$P2}
