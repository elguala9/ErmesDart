import 'dart:developer' as developer;

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

/// Registers a new symmetric cipher with [ErmesPeerCipherHandler] using
/// the key material reported by the peer. Errors are logged and
/// swallowed: key-exchange failures must not break communication.
void handleNewKeyMessage(ServiceMessageNewKey mess, IdAccountType peerId) {
  try {
    final handler = ErmesPeerCipherHandler();
    var peerCipher = handler.get(peerId);
    if (peerCipher == null) {
      peerCipher = createErmesPeerCipher() as ErmesPeerCipher;
      handler.set(peerId, peerCipher);
    }
    final symmetricCipher = generateSymmetric(
      mess.key,
      mess.algorithm,
      mess.expiration,
    );
    peerCipher.addDecryptCipher(symmetricCipher);
  } on Exception catch (e, stackTrace) {
    developer.log(
      'Error handling new key',
      name: 'ermes_core.ErmesService',
      error: e,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}

/// Builds the outgoing key-exchange service message.
ServiceMessageNewKey buildNewKeyMessage({
  required IdType newId,
  required CryptoAlgorithm algorithm,
  required String key,
  DateTime? start,
  DateTime? expiration,
  int? startMessage,
  int? endMessage,
}) =>
    ServiceMessageNewKey(
      id: newId,
      algorithm: algorithm,
      key: key,
      start: start,
      expiration: expiration,
      startMessage: startMessage,
      endMessage: endMessage,
    );
