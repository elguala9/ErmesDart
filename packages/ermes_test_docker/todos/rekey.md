# TODO — rekey

**Scenario**: `NAT_SCENARIO=rekey`
**Status**: [ ] not started

## Goal
Rotate the symmetric key mid-session (`ServiceMessageNewKey`) on a live
heartbeat and verify messages before and after the rotation decrypt with the
right key, with no dropped or garbled message at the boundary.

## Core path
- `ServiceMessageNewKey` handler (`_handleNewKey`) registering a new decryption
  cipher via `ErmesPeerCipherHandler`.
- `generateSymmetricFromString()` in `ermes_cipher_factories.dart`.

## Setup
Two PCs, cipher enabled, sustained heartbeat.

## Steps
1. Establish the encrypted heartbeat.
2. Trigger a key rotation while messages keep flowing.
3. Continue the heartbeat after the new key is active.

## Asserts (strict)
- Messages before rotation decrypt with the old key, after with the new key.
- No message is dropped or fails to decrypt at the switch boundary.

## Metric line
`rekey beforeKey=<n> afterKey=<n> boundaryFailures=0`
