import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:crypto/crypto.dart' show Digest;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

/// Registers the ECDH shared-secret cipher derived from a peer signal's
/// public key on the per-Connection [ErmesPeerCipher] held by
/// [ErmesPeerCipherHandler], keyed by `peerCipherKey(peer, context)`.
///
/// A re-dial toward a fresher signal (e.g. the first dial hit a stale signal
/// left on the relay by a previous process of the peer) derives a NEW key.
/// Signal ciphers carry no expiration, so [ErmesPeerCipher] would keep
/// encrypting with the first (stale) one: the peer, which only knows the
/// fresh key, would drop every frame. So the previously signal-derived
/// ENCRYPT cipher is retired; its decrypt cipher is kept for in-flight frames.
class OrcSignalCipherApplier {
  /// Creates an applier deriving shared secrets with [_keyExchange].
  OrcSignalCipherApplier(this._keyExchange);

  final IKeyExchange _keyExchange;

  /// Key id of the last signal-derived ENCRYPT cipher registered, per
  /// Connection cipher key.
  final Map<String, Digest> _lastKeyIds = {};

  /// Derives the directional ciphers for [remotePublicKey] (RFC 8.2): the
  /// local->remote key becomes the encryption cipher toward [peer] over the
  /// [context] Connection, the remote->local key is registered for
  /// decryption. No-op when [remotePublicKey] is empty.
  void apply(
    IdAccountType peer,
    String remotePublicKey,
    ErmesConnectionContext context,
  ) {
    if (remotePublicKey.isEmpty) {
      return;
    }
    final pair =
        deriveDirectionalCiphers(_keyExchange, remotePublicKey, context);
    final cipher = pair.encrypt;
    final key = peerCipherKey(peer, context);
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
}
