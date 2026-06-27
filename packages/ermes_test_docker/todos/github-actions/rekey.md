# TODO — rekey

**Scenario**: `NAT_SCENARIO=rekey`
**CI fit**: ✅ pure exchange + key rotation, no network manipulation
**Status**: [x] implemented (`NatRekeyExchange`), not yet run in CI
**Driver**: `sh scripts/run-test-github-rekey.sh`

## Goal
Rotate the symmetric key mid-session (`ServiceMessageNewKey`) on a live
heartbeat between your local PC and the runner, and verify messages before and
after the rotation decrypt with the right key — no dropped/garbled message at
the boundary.

## Core path
- `ServiceMessageNewKey` handler (`_handleNewKey`) registering a new decryption
  cipher via `ErmesPeerCipherHandler`.
- `generateSymmetricFromString()` in `ermes_cipher_factories.dart`.

## Actions wiring
- `side=b-only` (responder on the runner), initiator local; cipher enabled.
- The local initiator triggers the key rotation while the sustained heartbeat
  keeps flowing (reuse `NatHeartbeatInitiator`).
- `NAT_SCENARIO=rekey` selects the sustained-heartbeat-with-rotation path.

## Asserts (strict)
- Messages before rotation decrypt with the old key, after with the new key.
- No message dropped or undecryptable at the switch boundary.

## Metric line
`rekey beforeKey=<n> afterKey=<n> boundaryFailures=0`

## Runner caveats
- Keep the run inside the job `timeout-minutes` (default 15).
