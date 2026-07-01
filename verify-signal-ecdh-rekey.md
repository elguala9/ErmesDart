# VERIFY — signal-carried ECDH pubkey + shared-secret rekey

**Status**: [ ] open concerns — need a real 2-peer / CI run to confirm
**Related**: [verify-cipher-reuse-on-new-signal.md](verify-cipher-reuse-on-new-signal.md)

## What changed (context)

- A new signal now carries the **local ECDH public key**; on every (re)dial the
  opener derives the shared-secret cipher from the peer's signal and registers
  it (encrypt + decrypt) on the retained `ErmesPeerCipher`.
  - `packages/ermes_core/lib/src/orc_ermes_connection_opener.dart`
    (`_localPublicKey()`, `_applySharedSecret()`, `createSignal(peer, …)` call)
  - `deriveSharedSecretCipher()` in
    `packages/ermes_cipher/lib/src/factories/ermes_cipher_factories.dart`
- CI scenario `signal-cipher` added
  (`packages/ermes_test_shared/lib/src/nat_signal_cipher_exchange.dart`,
  `.github/workflows/nat-signal-cipher.yml`,
  `scripts/run-test-github-signal-cipher.sh`).

Everything below is verified **only** by unit/mock tests + `dart analyze`. None
of it has been run over a real 2-peer link / nostr relay.

## Doubts to verify

### 1. Always-on encryption may break existing harness scenarios
`OrcErmes` defaults `enableEncryption = true` (`orc_ermes.dart:31`) and the NAT
harness uses the DI `OrcErmes`. So `_applySharedSecret` now fires in **every**
scenario (encrypted, rekey, reconnect, load, plain burst) — previously traffic
was effectively plaintext (nothing seeded a cipher; see
`verify-cipher-reuse-on-new-signal.md`).
- [ ] Do the plaintext-assuming scenarios (reconnect / load / default burst)
      still pass now that frames are actually encrypted?
- [ ] Timing: can peer A send an encrypted frame **before** peer B has dialed
      and registered the shared decrypt cipher? (rendezvous ping/pong flood in
      `nat_rendezvous.dart` runs before both sides are guaranteed to have
      registered.) If so, early frames are dropped until B catches up — tolerable
      (retries) or fatal?

### 2. Signal cipher shadows the `rekey` rotation
`ErmesPeerCipher.encrypt` uses `_encryptCiphers[0]` (sorted by expiration).
The signal-derived shared cipher has **no expiration**, so it can outrank the
harness's rotated key and stay the encrypt cipher across the rotation.
- [ ] Does `rekey` still meaningfully test rotation, or does the shared cipher
      make `beforeKey`/`afterKey` use the same key? (Frames still decrypt — both
      keyIds are in the decrypt map — so `boundaryFailures=0` may pass while the
      rotation is effectively a no-op.)
- [ ] Decide isolation: add a flag to suppress the signal-derived rekey in the
      `rekey`/`encrypted` scenarios so they test only the data-channel path.

### 3. ECDH public key on the real wire
Only the `toString()`/`fromString()` round-trip is tested locally
(`ermes_signal_type.dart:60,66` — pipe-delimited, exactly 8 parts).
- [ ] Does the PEM public key (newlines, ~length) survive the **real nostr
      relay** transport intact, and never contain a `|`?
- [ ] Signal size: does the larger payload stay within relay limits / does
      compression handle it?

### 4. `_localPublicKey()` requires the ECDH DI to be registered
Guarded by `enableEncryption`; `initialPointErmesCore` registers `IKeyExchange`
(`initial_point_ermes_core.dart:59`). But other entry points may enable
encryption without initialising the cipher DI.
- [ ] Any path where `enableEncryption == true` but `IKeyExchange` is NOT in
      `SingletonDIAccess` → `_localPublicKey()` throws on `createSignal`.

### 5. End-to-end encryption actually happens in production
The "traffic was plaintext before / is encrypted now" claim is a code-path
deduction (`ermes_send_root_builder.dart:31` encrypts only when a cipher is
registered), not an on-wire observation.
- [ ] Capture the real bytes in a 2-peer run: plaintext before this change,
      ciphertext after (`ciphertextOnWire=true`).

## Expected asserts (if run)

- `signal-cipher signalCipher=true messages=5 decryptOk=true`
- Existing `encrypted` / `rekey` / reconnect scenarios still PASS.
- No undecryptable frame and no dropped message at connection start or across a
  reconnect/rotation boundary.
