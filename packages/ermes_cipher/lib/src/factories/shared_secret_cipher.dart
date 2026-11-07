import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';

import '../key_exchange/ecdh_serialization_helpers.dart';
import 'ermes_cipher_factories.dart';
import 'ermes_kdf.dart';

/// Derive the session symmetric cipher from a peer's raw ECDH public key,
/// using [local] to compute the ECDH shared secret (RFC section 8.1).
///
/// The shared secret is passed through HKDF-SHA256 with salt = SHA-256 of
/// both public keys (sorted) and info = `ermes-v3|<family>`, so each
/// Connection ([context]) to the same peer gets its own key. Both peers
/// derive identical key bytes for the same [context]. Only the peer's public
/// key is needed, so this is safe to feed with a key taken off the wire.
ISymmetricCipher deriveSharedSecretCipher(
  IKeyExchange local,
  String remotePublicKey,
  ErmesConnectionContext context, [
  CryptoAlgorithm? symmetricAlg,
]) {
  final sharedSecret = local.generateSharedSecret(remotePublicKey);
  final ikm = hexStringToBytes(cleanHexString(sharedSecret));
  final key = ermesHkdfSha256(
    ErmesKdfInput.forSession(
      sharedSecret: ikm,
      localPublicKey: local.publicKey,
      remotePublicKey: remotePublicKey,
      context: context,
    ),
  );
  return generateSymmetric(key, symmetricAlg ?? defaultSymmetricValue);
}
