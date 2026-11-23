import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:crypto/crypto.dart' show Digest;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

/// Remote key material a Connection's ciphers were last derived from.
class _AppliedKey {
  _AppliedKey(this.peer, this.remotePublicKey, this.context, this.idSignaling);

  final IdAccountType peer;
  final String remotePublicKey;
  final ErmesConnectionContext context;
  final String? idSignaling;
}

/// Registers the ECDH shared-secret cipher derived from a peer signal's
/// public key on the per-Connection [ErmesPeerCipher] held by
/// [ErmesPeerCipherHandler], keyed by `peerCipherKey(peer, context)`.
///
/// Every (re-)derivation (a fresher signal on re-dial, or a public-key
/// rotation on either side, RFC 8.6) makes the new encrypt key current and
/// retires the previously signal-derived ENCRYPT cipher. Decrypt ciphers are
/// never removed here: the bounded key ring keeps the prior ones, which is
/// the grace period for frames already in flight under the old key.
class OrcSignalCipherApplier {
  /// Creates an applier deriving shared secrets with [_keyExchange].
  OrcSignalCipherApplier(this._keyExchange);

  final IKeyExchange _keyExchange;

  /// Key id of the last signal-derived ENCRYPT cipher registered, per
  /// Connection cipher key.
  final Map<String, Digest> _lastKeyIds = {};

  /// Remote key last applied, per Connection cipher key.
  final Map<String, _AppliedKey> _applied = {};

  /// Derives the directional ciphers for [remotePublicKey] (RFC 8.2): the
  /// local->remote key becomes the encryption cipher toward [peer] over the
  /// [context] Connection, the remote->local key is registered for
  /// decryption. [idSignaling] is the publisher of [remotePublicKey], when
  /// known. No-op when [remotePublicKey] is empty.
  void apply(
    IdAccountType peer,
    String remotePublicKey,
    ErmesConnectionContext context, {
    String? idSignaling,
  }) {
    if (remotePublicKey.isEmpty) {
      return;
    }
    final key = peerCipherKey(peer, context);
    final known = idSignaling ?? _applied[key]?.idSignaling;
    _applied[key] = _AppliedKey(peer, remotePublicKey, context, known);
    final pair =
        deriveDirectionalCiphers(_keyExchange, remotePublicKey, context);
    final cipher = pair.encrypt;
    final handler = ErmesPeerCipherHandler();
    var peerCipher = handler.get(key);
    if (peerCipher == null) {
      peerCipher = ErmesPeerCipher();
      handler.set(key, peerCipher);
    }
    final previous = _lastKeyIds[key];
    if (previous != null && previous != cipher.keyId) {
      peerCipher.removeEncryptCipher(previous);
    }
    _lastKeyIds[key] = cipher.keyId;
    peerCipher
      ..addEncryptCipher(cipher)
      ..addDecryptCipher(pair.decrypt);
  }

  /// Re-derives every applied Connection against the CURRENT local key pair
  /// (after a local public-key rotation, RFC 8.6).
  void reapplyAll() {
    for (final a in List.of(_applied.values)) {
      apply(a.peer, a.remotePublicKey, a.context);
    }
  }

  /// Applies [signal]'s public key to every Connection toward [peer] whose
  /// ciphers came from the same IdSignaling but a different public key (an
  /// out-of-band rotation, RFC 8.6). Returns whether anything was re-derived.
  bool applyIfRotated(IdAccountType peer, ISignalErmes signal) {
    var changed = false;
    for (final a in List.of(_applied.values)) {
      if (a.peer == peer &&
          a.idSignaling == signal.idSignaling &&
          signal.publicKey.isNotEmpty &&
          a.remotePublicKey != signal.publicKey) {
        apply(peer, signal.publicKey, a.context);
        changed = true;
      }
    }
    return changed;
  }

  /// Re-derives the [context] Connection toward [peer] whenever [service]
  /// receives an in-band `newpubkey` (RFC 8.6).
  void listen(
    IdAccountType peer,
    IErmesService service,
    ErmesConnectionContext context,
  ) =>
      service.addOnNewPubKeyListener((m) => apply(peer, m.key, context));
}
