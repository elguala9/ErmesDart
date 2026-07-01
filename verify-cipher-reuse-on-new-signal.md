# VERIFY — cipher/shared-secret reuse on a new signal

**Status**: [ ] open concern — needs verification
**Related**: [rekey-on-reconnect.md](rekey-on-reconnect.md), [rekey.md](rekey.md)

## The concern

When a **new signal** arrives for a peer, the transport is rebuilt but the
encryption state (the ECDH-derived shared secret and its ciphers) is **reused**,
not renegotiated. This may be wrong when the new signal carries fresh ECDH key
material from the peer.

## What the code does today

1. `ErmesSignalingHandler.processSignal()` — creates a new `ShspInstance`
   unconditionally. No check for an existing connection.
   - `packages/ermes_signaling/lib/src/ermes_signaling_handler.dart:90`

2. `handshake()` — overwrites the transport for that peer:
   ```dart
   activeConnections[from] = instance; // replaces any existing connection
   ```
   - `packages/ermes_signaling/lib/src/ermes_signaling_handler_connections.dart`

3. **Ciphers are NOT touched.** They live in the singleton
   `ErmesPeerCipherHandler`, keyed by peer id, and are looked up/reused.
   - `packages/ermes_cipher/lib/src/ermes_peer_cipher_handler.dart:12`

4. The ECDH key exchange (`ECDHKeyExchangeService.generateISymmetric` →
   `generateSharedSecret`) is **NOT** triggered by a signal. It runs only at the
   initial crypto setup.
   - `packages/ermes_cipher/lib/src/key_exchange/ecdh_key_exchange_service.dart:117`

5. `handleNewKeyMessage()` **adds** a decrypt cipher (does not replace), so
   multiple keys can be valid during a rotation.
   - `packages/ermes_core/lib/src/ermes_service_key_handler.dart:12`

Net effect: **new signal = new transport connection, same crypto state.**

## Why it doesn't convince me

Two cases collapse into the same code path, but only one is correct:

| Case | Reuse the old shared secret? | Result today |
|---|---|---|
| Same peer just reconnects (NAT/IP change, dropped socket), ECDH material unchanged | Correct — avoids a needless re-handshake | ✅ works |
| New signal carries **fresh** ECDH keys (peer regenerated its ephemeral pair) | Wrong — we never derive the new shared secret | ❌ post-reconnect frames become undecryptable |

There is **no branch** that distinguishes these cases: the incoming signal is
never inspected to decide whether the existing shared secret is still valid, and
`generateISymmetric` is never re-invoked on signal arrival. So if the peer ever
rotates its ECDH key and re-signals, we would keep encrypting/decrypting with a
stale secret.

The existence of `rekey-on-reconnect.md` (still "not started") suggests the
"re-negotiate on reconnect" path was intended but is not implemented/covered.

## What to verify

- [ ] Does an incoming signal ever carry new ECDH public-key material? (inspect
      `ISignalErmes` payload and how the peer builds it on reconnect)
- [ ] If yes: is there any point where a new signal re-triggers
      `generateISymmetric` / a fresh `addEncryptCipher` + `addDecryptCipher`?
- [ ] If no such point exists: confirm this is a real bug (undecryptable frames
      after a peer-side ECDH rotation), not just a theoretical one.
- [ ] Decide the intended contract: reuse-by-default vs. always-renegotiate vs.
      renegotiate-only-when-signal-key-differs.

## Expected assert (if a test is written)

`new-signal-rekey postReconnectDecryptOk=true staleSecretReused=false`
