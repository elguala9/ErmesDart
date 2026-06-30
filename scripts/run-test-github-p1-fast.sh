#!/bin/sh
# Runs the FAST subset of the P1 reconnection family — every P1 scenario EXCEPT
# long-outage (which alone is >10 min). Meant for quick iteration:
#
#   graceful-reconnect  local peer closes its link; the core re-rendezvous
#   peer-restart        the local peer is hard-killed and relaunched
#   flap                sub-threshold pause; link must NOT tear down
#   flap-storm          repeated break/reconnect cycles (FLAP_CYCLES)
#
# Thin wrapper over run-test-github-all.sh, so the per-scenario verdict,
# sequencing and summary all come from that one driver. Run the full P1 set
# (including long-outage) with run-test-github-p1.sh.
#
# Usage (from the repo, in a terminal):
#   sh scripts/run-test-github-p1-fast.sh             # the fast P1 subset
#   sh scripts/run-test-github-p1-fast.sh flap        # only the listed one
#
# Env: every override honoured by run-test-github-all.sh / lib/github-nat-driver.sh.
# Works on Linux, macOS and Windows (Git Bash). Requires `gh` (authenticated)
# and the Dart SDK.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# P1 without long-outage. Order: cheap reactive checks first.
P1_FAST="graceful-reconnect peer-restart flap flap-storm"

exec sh "$SCRIPT_DIR/run-test-github-all.sh" ${*:-$P1_FAST}
