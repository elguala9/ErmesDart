#!/bin/sh
# Runs the P5 adverse-condition GitHub Actions NAT scenarios in sequence and
# reports which failed. The degradation is applied by the workflow to the runner
# peer-b (Linux + root: tc netem / ip link set mtu); the local peer-a is clean:
#
#   lossy           tc netem loss LOSS_PCT%; delivery still completes (gaps=0)
#   latency-jitter  tc netem delay/jitter; no false disconnect, no duplicates
#   mtu-edge        ip link set mtu MTU; reassembly correct, no oversized drop
#
# Thin wrapper over run-test-github-all.sh with the P5 subset. Tune the netem
# values via the workflow env (LOSS_PCT / DELAY_MS / JITTER_MS / MTU).
#
# Usage:
#   sh scripts/run-test-github-p5.sh                # all P5 scenarios
#   sh scripts/run-test-github-p5.sh lossy          # only the listed one
#
# Works on Linux, macOS and Windows (Git Bash). Requires `gh` and the Dart SDK.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
P5="lossy latency-jitter mtu-edge"
exec sh "$SCRIPT_DIR/run-test-github-all.sh" ${*:-$P5}
