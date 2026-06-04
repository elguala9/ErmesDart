import 'dart:convert';
import 'dart:typed_data';

import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

import 'ermes_utility/hash_utils.dart';
import 'exceptions.dart';
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

Uint8List _extractPlaintext(MessageRoot messRoot, IdAccountType peerId) {
  if (messRoot.digest case final digest?) {
    final handler = ErmesPeerCipherHandler();
    final ermesPeerCipher = handler.get(peerId);
    if (ermesPeerCipher == null) {
      throw CoreException('Cipher not found for peer');
    }
    return ermesPeerCipher.decrypt(
      DataEncrypted(digest, messRoot.messageSerialized),
    );
  }
  if (messRoot.messageJson case final json?) {
    return Uint8List.fromList(utf8.encode(jsonEncode(json)));
  }
  return messRoot.messageSerialized;
}
