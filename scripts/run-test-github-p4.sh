#!/bin/sh
# Runs the P4 load / stress GitHub Actions NAT scenarios in sequence and reports
# which failed. Pure exchange — no network manipulation:
#
#   throughput     sustain TARGET_RATE msg/s for DURATION; report rate+latency
#   large-payload  sweep SIZES; checksum each reassembled payload
#   keepalive      idle IDLE_DURATION, then resume without a re-rendezvous
#
# Thin wrapper over run-test-github-all.sh with the P4 subset.
#
# Usage:
#   sh scripts/run-test-github-p4.sh                # all P4 scenarios
#   sh scripts/run-test-github-p4.sh throughput     # only the listed one
#
# Works on Linux, macOS and Windows (Git Bash). Requires `gh` and the Dart SDK.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
P4="throughput large-payload keepalive"
exec sh "$SCRIPT_DIR/run-test-github-all.sh" ${*:-$P4}
