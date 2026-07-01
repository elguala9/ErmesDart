#!/bin/sh
# GitHub Actions driver — NAT_SCENARIO=signal-cipher (P3).
#
# Proves the link is encrypted using ONLY the ECDH public key carried in the
# signal (the production OrcConnectionOpener path), with NO in-band cipher
# handshake. peer-B (responder) runs on a GitHub runner and peer-A (initiator)
# runs locally; both derive the shared secret from each other's signal and
# exchange an encrypted burst.
#
# Run `run-test-github-encrypted.sh` first: if the encrypted smoke test cannot
# rendezvous, this cannot either.
#
# Usage (from the repo, in a terminal):
#   sh scripts/run-test-github-signal-cipher.sh
#
# Works on Linux, macOS and Windows (Git Bash). Requires `gh` (authenticated)
# and the Dart SDK. See lib/github-nat-driver.sh for env overrides.
set -eu

SCENARIO=signal-cipher
. "$(dirname "$0")/lib/github-nat-driver.sh"

trigger_runner "$SCENARIO"
compile_local
rc=0
run_local "$SCENARIO" || rc=$?
report_and_exit "$rc" "$SCENARIO"
