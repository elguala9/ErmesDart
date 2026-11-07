import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:iermes/iermes.dart';

import '../exceptions.dart';

/// Protocol label prefixed to the KDF `info` field.
const String ermesKdfLabel = 'ermes-v3';

/// SHA-256 output length in bytes.
const int _hashLength = 32;

/// Parameters of one HKDF-SHA256 derivation (RFC 5869).
class ErmesKdfInput {
  /// Creates the input; [length] is the output key length in bytes.
  ErmesKdfInput({
    required this.ikm,
    required this.salt,
    required this.info,
    this.length = _hashLength,
  });

  /// Input for the session key between two peers (RFC section 8.1): salt
  /// is SHA-256 of the two public keys sorted, info is `ermes-v3|<family>`.
  factory ErmesKdfInput.forSession({
    required Uint8List sharedSecret,
    required String localPublicKey,
    required String remotePublicKey,
    required ErmesConnectionContext context,
  }) =>
      ErmesKdfInput(
        ikm: sharedSecret,
        salt: ermesSessionSalt(localPublicKey, remotePublicKey),
        info: Uint8List.fromList(utf8.encode(ermesSessionInfo(context))),
      );


  /// Input keying material (the ECDH shared secret).
  final Uint8List ikm;

  /// Extract salt.
  final Uint8List salt;

  /// Expand context information.
  final Uint8List info;

  /// Requested output length in bytes (1..255*32).
  final int length;
}

/// Info string for the first session key: `ermes-v3|ipv4` or `ermes-v3|ipv6`.
String ermesSessionInfo(ErmesConnectionContext context) =>
    '$ermesKdfLabel|${context.label}';

/// SHA-256 over the two public keys, sorted so both peers agree.
Uint8List ermesSessionSalt(String keyA, String keyB) {
  final a = keyA.trim().toLowerCase();
  final b = keyB.trim().toLowerCase();
  final sorted = a.compareTo(b) <= 0 ? [a, b] : [b, a];
  return Uint8List.fromList(
    sha256.convert(utf8.encode(sorted.join('|'))).bytes,
  );
}

/// HKDF-SHA256 (RFC 5869): extract then expand.
Uint8List ermesHkdfSha256(ErmesKdfInput input) {
  if (input.ikm.isEmpty) {
    throw CipherException('KDF input keying material must not be empty');
  }
  if (input.length < 1 || input.length > 255 * _hashLength) {
    throw CipherException('KDF output length out of range: ${input.length}');
  }
  final salt = input.salt.isEmpty ? Uint8List(_hashLength) : input.salt;
  final prk = Hmac(sha256, salt).convert(input.ikm).bytes;
  final okm = BytesBuilder(copy: false);
  var previous = <int>[];
  for (var i = 1; okm.length < input.length; i++) {
    previous = Hmac(sha256, prk)
        .convert([...previous, ...input.info, i])
        .bytes;
    okm.add(previous);
  }
  return Uint8List.fromList(okm.takeBytes().sublist(0, input.length));
}
