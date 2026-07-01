import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

import 'logging/ermes_log.dart';

/// Logger for key-handling events.
final _log = ermesLoggerFor('ErmesService');

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
    _log.severe('Error handling new key', e, stackTrace);
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
