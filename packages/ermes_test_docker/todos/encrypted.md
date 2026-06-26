# TODO — encrypted

**Scenario**: `NAT_SCENARIO=encrypted`
**Status**: [ ] not started

## Goal
Run the default exchange end to end with encryption enabled over real NAT.
Confirms the ECDH handshake and AES round-trip work outside in-process tests,
where real timing and reconnection interact with key state.

## Core path
- `ermes_cipher`: ECDH key exchange, AES symmetric encrypt/decrypt.
- Cipher wired into `ErmesSendRepo` (encrypt) / `ErmesReadRepo` (decrypt).

## Setup
Two PCs with cipher enabled in the `OrcErmes` setup.

## Steps
1. Establish the connection; perform the ECDH handshake.
2. Exchange the `testData`/`ack` batch with encryption on.
3. Capture a payload on the wire for inspection.

## Asserts (strict)
- On-wire payload is ciphertext (does not contain the plaintext bytes).
- Both sides decrypt correctly; ACKs match the plaintext sequence.

## Metric line
`encrypted handshakeMs=<n> messages=<n> ciphertextOnWire=true decryptOk=true`
