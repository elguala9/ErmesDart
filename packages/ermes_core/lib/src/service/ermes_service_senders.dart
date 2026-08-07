import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';

import '../repository/ermes_send_repo.dart';
import 'ermes_service_key_handler.dart';

/// Builds and dispatches outgoing service messages (acknowledge, key
/// exchange) for [ErmesService]. Extracted to keep the service class focused
/// on coordination.
mixin ErmesServiceSenders {
  /// Id handler used to mint message ids.
  IIdHandlerService get idHandler;

  /// Transport repository the service sends through.
  ErmesSendRepo get ermesSendRepo;

  /// Optional message-control service used to report the last received id.
  IErmesMessageControlService? get ermesMessageControlService;

  /// Sends an acknowledge service message with the current id watermarks.
  void sendAcknowledge() {
    final msg = ServiceMessageAcknowledge(
      id: idHandler.getNewId(),
      ackCurrentId: idHandler.getCurrent(),
      ackLastReceivedId: ermesMessageControlService?.getLastReceivedId(),
    );
    ermesSendRepo.sendMessageType([MessageType.service(msg)]);
  }

  /// Sends a new-key service message advertising a fresh symmetric key.
  void sendNewKey({
    required CryptoAlgorithm algorithm,
    required String key,
    DateTime? start,
    DateTime? expiration,
    int? startMessage,
    int? endMessage,
  }) {
    final msg = buildNewKeyMessage(
      newId: idHandler.getNewId(),
      algorithm: algorithm,
      key: key,
      start: start,
      expiration: expiration,
      startMessage: startMessage,
      endMessage: endMessage,
    );
    ermesSendRepo.sendMessageType([MessageType.service(msg)]);
  }
}
