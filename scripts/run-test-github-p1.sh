#!/bin/sh
# Runs the P1 reconnection-family GitHub Actions NAT scenarios in sequence and
# reports which failed. P1 covers the link-loss / re-rendezvous contract:
#
#   graceful-reconnect  local peer closes its link; the core re-rendezvous
#   peer-restart        the local peer is hard-killed and relaunched
#   flap                sub-threshold pause; link must NOT tear down
#   flap-storm          repeated break/reconnect cycles (FLAP_CYCLES)
#   long-outage         outage >10 min (raise TIMEOUT_MINUTES)
#
# Thin wrapper over run-test-github-all.sh with the P1 subset, so the per-
# scenario verdict, sequencing and summary all come from that one driver.
#
# Usage (from the repo, in a terminal):
#   sh scripts/run-test-github-p1.sh                       # all P1 scenarios
#   sh scripts/run-test-github-p1.sh flap flap-storm       # only the listed ones
#
# Env: every override honoured by run-test-github-all.sh / lib/github-nat-driver.sh
# (LOG_DIR, TIMEOUT_MINUTES, ERMES_NAT_REF, FLAP_CYCLES, RESTART_AFTER, ...).
#
# Heads-up: long-outage alone is >10 min. Pass a subset while iterating.
# Works on Linux, macOS and Windows (Git Bash). Requires `gh` (authenticated)
# and the Dart SDK.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Order matters: cheap reactive checks first, the long outage last.
P1="graceful-reconnect peer-restart flap flap-storm long-outage"

exec sh "$SCRIPT_DIR/run-test-github-all.sh" ${*:-$P1}
