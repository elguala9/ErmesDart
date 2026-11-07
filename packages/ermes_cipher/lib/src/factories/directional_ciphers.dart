import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';

import '../key_exchange/ecdh_serialization_helpers.dart';
import 'ermes_cipher_factories.dart';
import 'ermes_kdf.dart';

/// The two directional session ciphers toward one counterpart (RFC 8.2).
class ErmesDirectionalCiphers {
  /// Creates the pair.
  const ErmesDirectionalCiphers({required this.encrypt, required this.decrypt});

  /// Key for local -> remote frames.
  final ISymmetricCipher encrypt;

  /// Key for remote -> local frames.
  final ISymmetricCipher decrypt;
}

/// Info string for one direction: `ermes-v3|<family>|<direction>`.
///
/// The direction is named from the sorted public keys (`lo` sorts first), so
/// A's `lo>hi` key is exactly B's view of the same direction. When both keys
/// are equal (self-connection) no direction exists and `self` is used for
/// both: the same key then serves both directions (no RFC 8.2 guarantee is
/// possible on a loopback).
String ermesDirectionalInfo(
  ErmesConnectionContext context,
  String senderPublicKey,
  String receiverPublicKey,
) {
  final s = senderPublicKey.trim().toLowerCase();
  final r = receiverPublicKey.trim().toLowerCase();
  final cmp = s.compareTo(r);
  final direction = cmp == 0 ? 'self' : (cmp < 0 ? 'lo>hi' : 'hi>lo');
  return '${ermesSessionInfo(context)}|$direction';
}

/// Derives distinct encrypt/decrypt ciphers from the ECDH secret between
/// [local] and [remotePublicKey] (HKDF-SHA256, RFC 8.1/8.2). The remote
/// peer's encrypt cipher equals our decrypt cipher and vice versa.
ErmesDirectionalCiphers deriveDirectionalCiphers(
  IKeyExchange local,
  String remotePublicKey,
  ErmesConnectionContext context, [
  CryptoAlgorithm? symmetricAlg,
]) {
  final secret = local.generateSharedSecret(remotePublicKey);
  final ikm = hexStringToBytes(cleanHexString(secret));
  final salt = ermesSessionSalt(local.publicKey, remotePublicKey);
  final alg = symmetricAlg ?? defaultSymmetricValue;
  ISymmetricCipher derive(String sender, String receiver) {
    final info = ermesDirectionalInfo(context, sender, receiver);
    final key = ermesHkdfSha256(
      ErmesKdfInput(
        ikm: ikm,
        salt: salt,
        info: Uint8List.fromList(utf8.encode(info)),
      ),
    );
    return generateSymmetric(key, alg);
  }

  return ErmesDirectionalCiphers(
    encrypt: derive(local.publicKey, remotePublicKey),
    decrypt: derive(remotePublicKey, local.publicKey),
  );
}
