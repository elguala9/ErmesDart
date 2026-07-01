# TODO — signal-cipher

**Scenario**: `NAT_SCENARIO=signal-cipher`
**CI fit**: ✅ pure exchange, no network manipulation
**Status**: [x] implemented (`NatSignalCipherExchange`), not yet run in CI
**Driver**: `sh scripts/run-test-github-signal-cipher.sh`

## Goal
Prove the link is encrypted using **only the ECDH public key carried in the
signal** — the production `OrcConnectionOpener` path — with **no in-band cipher
handshake** (`NatCipherSession`/`NatCipherHandshake`). This is the counterpart
to `encrypted`, which exchanges the ECDH keys over the data channel; here the
keys travel in the nostr signal and the shared secret is derived on dial.

## Core path
- `OrcConnectionOpener.open()` → `createSignal(peer, <local ECDH public key>)`
  so the published signal carries the local ECDH public key.
- `OrcConnectionOpener._applySharedSecret()` derives the shared-secret cipher
  from `peerSignal.publicKey` via `deriveSharedSecretCipher` and registers it
  (encrypt + decrypt) on the retained `ErmesPeerCipher` on every (re)dial.
- `buildMessageRoot` then encrypts every `OrcErmes.send` transparently.

## Actions wiring
- `side=b-only` (responder on the runner), initiator local; cipher enabled
  (the default `OrcErmes` `enableEncryption = true`).
- No handshake frames are exchanged — the engine asserts, right after
  rendezvous, that a real encrypt cipher is registered for the peer, then runs
  an encrypted burst.
- `NAT_SCENARIO=signal-cipher` selects the engine on both peers.

## Asserts (strict)
- An encrypt cipher is registered for the peer after rendezvous (the
  signal-derived shared secret ran) — else fail loud.
- All `messageCount` messages are acknowledged, i.e. both sides derived the
  SAME shared secret off the wire and decrypt correctly.

## Metric line
`signal-cipher signalCipher=true messages=<n> decryptOk=true`

## Runner caveats
- Run `run-test-github-encrypted.sh` first: if the encrypted smoke test cannot
  rendezvous, this cannot either.
- Keep the run inside the job `timeout-minutes` (default 15).
