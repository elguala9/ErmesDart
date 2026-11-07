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
  /// Completes once the frame has been encrypted (under the current outbound
  /// key) and dispatched, so callers can switch keys only afterwards.
  ///
  /// When [startMessage] is omitted it is the newkey id + 1 (RFC section
  /// 7.4): ids are monotonic and every frame is encrypted when its id is
  /// minted, so frames under the new key all carry later ids. [endMessage]
  /// stays absent unless given (the end id is not known ahead).
  Future<void> sendNewKey({
    required CryptoAlgorithm algorithm,
    required String key,
    DateTime? start,
    DateTime? expiration,
    int? startMessage,
    int? endMessage,
  }) async {
    final newId = idHandler.getNewId();
    final msg = buildNewKeyMessage(
      newId: newId,
      algorithm: algorithm,
      key: key,
      start: start,
      expiration: expiration,
      startMessage: startMessage ?? newId + 1,
      endMessage: endMessage,
    );
    await ermesSendRepo.sendMessageType([MessageType.service(msg)]);
  }
}
