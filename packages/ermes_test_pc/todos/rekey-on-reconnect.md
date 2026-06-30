# TODO — rekey-on-reconnect

**Scenario**: `NAT_SCENARIO=rekey-on-reconnect`
**Status**: [ ] not started

## Goal
Verify cipher state survives — or is correctly re-negotiated after — a network
change. Catches the failure mode where reconnect loses key material and
post-reconnect messages can no longer be decrypted.

## Core path
- Cipher state held by `ErmesPeerCipherHandler` across `openConnection()`.
- ECDH re-handshake on reconnect (if the design re-negotiates).

## Setup
Two PCs, cipher enabled. Combine the network-change break with encryption.

## Steps
1. Establish the encrypted heartbeat.
2. Force a network change (as in `network-change`).
3. After reconnect, continue the encrypted heartbeat.

## Asserts (strict)
- Messages after reconnect decrypt correctly (key preserved or re-negotiated).
- No silent plaintext fallback; no undecryptable messages.

## Metric line
`rekey-on-reconnect reconnectTimeMs=<n> postReconnectDecryptOk=true`
