# TODO — encrypted (CI smoke test)

**Scenario**: `NAT_SCENARIO=encrypted`
**CI fit**: ✅ ideal — pure exchange, no network manipulation
**Status**: [x] implemented (`NatEncryptedExchange`), not yet run in CI
**Driver**: `sh scripts/run-test-github-encrypted.sh`

## Goal
Run the default encrypted exchange end to end with **peer-B on a GitHub
runner** and **peer-A on your PC**. This is the first scenario to run: it proves
local↔Azure UDP hole-punch + ECDH/AES work before any harder scenario.

## Actions wiring
- Dispatch `nat-test.yml` with `side=b-only` (responder on the runner).
- Run `bin/nat_peer_a.dart` locally with the same `ALICE_PUBKEY`/`BOB_PUBKEY`,
  `NOSTR_RELAYS`, `STUN_HOST/PORT`, and `NAT_SCENARIO=encrypted`.
- Cipher must be enabled in the `OrcErmes` setup on both sides
  (`createDockerOrcErmes` config).
- Both binaries must branch on `NAT_SCENARIO=encrypted` (extend the
  `isNetworkChangeScenario()`-style dispatch) and enable the cipher path.

## Asserts (strict)
- On-wire payload is ciphertext (does not contain the plaintext bytes).
- Both sides decrypt correctly; ACKs match the plaintext sequence.

## Metric line
`encrypted handshakeMs=<n> messages=<n> ciphertextOnWire=true decryptOk=true`

## Runner caveats
- If this fails to rendezvous, the gating risk (home NAT ↔ Azure NAT) has hit —
  do not attempt the other CI scenarios until it passes.
