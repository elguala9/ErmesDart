import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:crypto/crypto.dart' show Digest;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

/// Registers the ECDH shared-secret cipher derived from a peer signal's
/// public key on the per-peer [ErmesPeerCipher] held by
/// [ErmesPeerCipherHandler].
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

  /// Key id of the last signal-derived cipher registered, per peer.
  final Map<IdAccountType, Digest> _lastKeyIds = {};

  /// Derives the cipher for [remotePublicKey] and makes it the encryption
  /// cipher toward [peer] (also registered for decryption). No-op when
  /// [remotePublicKey] is empty.
  void apply(IdAccountType peer, String remotePublicKey) {
    if (remotePublicKey.isEmpty) {
      return;
    }
    final cipher = deriveSharedSecretCipher(_keyExchange, remotePublicKey);
    final handler = ErmesPeerCipherHandler();
    var peerCipher = handler.get(peer);
    if (peerCipher == null) {
      peerCipher = ErmesPeerCipher();
      handler.set(peer, peerCipher);
    }
    final previous = _lastKeyIds[peer];
    if (previous != null && previous != cipher.keyId) {
      peerCipher.removeEncryptCipher(previous);
    }
    _lastKeyIds[peer] = cipher.keyId;
    peerCipher
      ..addEncryptCipher(cipher)
      ..addDecryptCipher(cipher);
  }
}
