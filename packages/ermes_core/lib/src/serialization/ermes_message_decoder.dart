import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

import '../support/ermes_receive_stats.dart';
import '../utility/hash_utils.dart';

export 'ermes_key_bounds_check.dart' show isWithinKeyBounds;

/// Plaintext + computed hash extracted from a wire-format [MessageRoot].
/// Returned by [decodeMessageEnvelope] when the envelope is valid and
/// has not been seen before. Returns `null` when the message must be
/// dropped (empty, bad version, integrity mismatch, or duplicate hash).
/// [digest] names the key that decrypted the frame (null for plaintext).
typedef DecodedEnvelope = ({
  Uint8List plainBytes,
  String hash,
  ProtocolVersion version,
  Digest? digest,
});

/// Strips the outer [MessageRoot]:
/// 0. Drops envelopes with an unsupported or malformed version `v`.
/// 1. Decrypts when `digest` is set (encrypted wire format).
/// 2. Re-serializes when `messageJson` is set (plaintext wire format).
/// 3. Treats `messageSerialized` as plaintext otherwise (legacy form).
/// Then verifies the integrity hash and rejects duplicates already
/// present in [processedHashes]. [onUnsupportedVersion] is told about a
/// well-formed envelope whose major cannot be parsed (RFC 7.1).
DecodedEnvelope? decodeMessageEnvelope(
  SerializableDataType message,
  String cipherKey,
  Set<String> processedHashes, {
  void Function(ProtocolVersion version)? onUnsupportedVersion,
}) {
  final stats = ErmesReceiveStats.active;
  if (message.isEmpty) {
    stats?.onDropEmpty();
    return null;
  }

  final parsed = _parseEnvelope(message, onUnsupportedVersion);
  if (parsed == null) {
    return null;
  }
  final (messRoot, version) = parsed;
  final plainBytes = _extractPlaintext(messRoot, cipherKey);

  if (plainBytes.isEmpty) {
    // Encrypted drops (no cipher / decrypt failure) are counted by
    // [_extractPlaintext]; only plaintext frames count as empty here.
    if (messRoot.digest == null) {
      stats?.onDropEmpty();
    }
    return null;
  }

  final computedHash = calculateHashSync(plainBytes);
  if (messRoot.integrityCheckValue.toString() != computedHash) {
    stats?.onDropHash();
    return null;
  }

  if (!processedHashes.add(computedHash)) {
    stats?.onDropDuplicate();
    return null;
  }

  return (
    plainBytes: plainBytes,
    hash: computedHash,
    version: version,
    digest: messRoot.digest,
  );
}

/// Parses the outer envelope, or returns null (counted as a version drop)
/// when its protocol version is unsupported or malformed. Like an
/// undecryptable frame, such a datagram must not crash the node.
(MessageRoot, ProtocolVersion)? _parseEnvelope(
  SerializableDataType message,
  void Function(ProtocolVersion version)? onUnsupportedVersion,
) {
  try {
    final json = jsonDecode(utf8.decode(message));
    if (json is! Map<String, dynamic>) {
      throw ErmesSerializationException('Envelope is not a JSON object');
    }
    final version = ProtocolVersion.parse(json['v']);
    if (!version.isSupported) {
      onUnsupportedVersion?.call(version);
    }
    return (MessageRoot.fromJson(json), version);
  } on ErmesSerializationException catch (e) {
    ErmesReceiveStats.active?.onDropVersion(e);
    return null;
  }
}

/// Extracts the plaintext payload from a [MessageRoot], decrypting when a
/// digest is present, re-encoding embedded JSON, or returning the raw
/// serialized bytes for legacy messages.
///
/// An encrypted frame that cannot be decrypted (no cipher registered for the
/// peer, or an unknown/foreign key digest) is not fatal: it is a stray or
/// hostile datagram arriving at the raw UDP socket, so it is dropped by
/// returning empty bytes (the caller maps empty plaintext to a dropped frame).
/// Crashing the isolate on such input would let any packet kill the node.
Uint8List _extractPlaintext(MessageRoot messRoot, String cipherKey) {
  if (messRoot.digest case final digest?) {
    final handler = ErmesPeerCipherHandler();
    final ermesPeerCipher = handler.get(cipherKey);
    if (ermesPeerCipher == null) {
      ErmesReceiveStats.active?.onDropNoCipher();
      return Uint8List(0);
    }
    try {
      return ermesPeerCipher.decrypt(
        DataEncrypted(digest, messRoot.messageSerialized),
      );
    } on CipherException catch (e) {
      ErmesReceiveStats.active?.onDropDecrypt(e);
      return Uint8List(0);
    }
  }
  if (messRoot.messageJson case final json?) {
    return Uint8List.fromList(utf8.encode(jsonEncode(json)));
  }
  return messRoot.messageSerialized;
}
