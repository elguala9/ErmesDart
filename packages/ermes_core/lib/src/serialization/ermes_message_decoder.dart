import 'dart:convert';
import 'dart:typed_data';

import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

import '../utility/hash_utils.dart';
import 'serialization_helpers.dart';

/// Plaintext + computed hash extracted from a wire-format [MessageRoot].
/// Returned by [decodeMessageEnvelope] when the envelope is valid and
/// has not been seen before. Returns `null` when the message must be
/// dropped (empty, integrity mismatch, or duplicate hash).
typedef DecodedEnvelope = ({Uint8List plainBytes, String hash});

/// Strips the outer [MessageRoot]:
/// 1. Decrypts when `digest` is set (encrypted v2 wire format).
/// 2. Re-serializes when `messageJson` is set (plaintext v2 wire format).
/// 3. Treats `messageSerialized` as plaintext otherwise (legacy v1).
/// Then verifies the integrity hash and rejects duplicates already
/// present in [processedHashes].
DecodedEnvelope? decodeMessageEnvelope(
  SerializableDataType message,
  IdAccountType remotePeerId,
  Set<String> processedHashes,
) {
  if (message.isEmpty) {
    return null;
  }

  final messRoot = uint8ArrayToObject<MessageRoot>(message);
  final plainBytes = _extractPlaintext(messRoot, remotePeerId);

  if (plainBytes.isEmpty) {
    return null;
  }

  final computedHash = calculateHashSync(plainBytes);
  if (messRoot.integrityCheckValue.toString() != computedHash) {
    return null;
  }

  if (!processedHashes.add(computedHash)) {
    return null;
  }

  return (plainBytes: plainBytes, hash: computedHash);
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
Uint8List _extractPlaintext(MessageRoot messRoot, IdAccountType peerId) {
  if (messRoot.digest case final digest?) {
    final handler = ErmesPeerCipherHandler();
    final ermesPeerCipher = handler.get(peerId);
    if (ermesPeerCipher == null) {
      return Uint8List(0);
    }
    try {
      return ermesPeerCipher.decrypt(
        DataEncrypted(digest, messRoot.messageSerialized),
      );
    } on CipherException {
      return Uint8List(0);
    }
  }
  if (messRoot.messageJson case final json?) {
    return Uint8List.fromList(utf8.encode(jsonEncode(json)));
  }
  return messRoot.messageSerialized;
}
