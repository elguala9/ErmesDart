import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

import 'ermes_utility/hash_utils.dart';
import 'utility.dart';

/// Builds a [MessageRoot] (wire format v2) from a [MessageType].
///
/// Encrypts plaintext bytes when a cipher is registered for [remotePeerId];
/// otherwise embeds the nested JSON directly. The integrity hash is always
/// computed on the plaintext bytes (before encryption).
MessageRoot buildMessageRoot(MessageType element, String remotePeerId) {
  final internalMessage = InternalMessage(
    message: element,
    type: getMessageType(element),
  );

  final innerJson = internalMessage.toJson();
  final innerBytes = Uint8List.fromList(utf8.encode(jsonEncode(innerJson)));
  final hash = calculateHashSync(innerBytes);

  Digest? digest;
  Uint8List? encryptedBytes;

  final ermesPeerCipher = ErmesPeerCipherHandler().get(remotePeerId);
  if (ermesPeerCipher != null) {
    final dataEncrypted = ermesPeerCipher.encrypt(innerBytes);
    encryptedBytes = dataEncrypted.encryptedData;
    digest = dataEncrypted.keyId;
  }

  return MessageRoot(
    messageJson: digest == null ? innerJson : null,
    messageSerialized: encryptedBytes ?? Uint8List(0),
    integrityCheckValue: hash,
    digest: digest,
  );
}
