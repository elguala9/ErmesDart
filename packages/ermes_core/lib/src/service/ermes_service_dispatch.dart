part of 'ermes_service.dart';

/// Private construction and dispatch helpers of [ErmesService].
extension _ErmesServiceDispatch on ErmesService {
  /// Builds the controller driving missing-message retransmission.
  MissingMessagesController _createMissingController() =>
      MissingMessagesController(
        controlService: ermesMessageControlService,
        sendRepo: ermesSendRepo,
        idHandler: _idHandler,
        threshold: missingMessagesThreshold,
        isOpen: () => !isConnectionClosed && isOpen(),
      );

  /// Dispatches an incoming service message to the appropriate handler.
  void _handleServiceMessage(ServiceMessage mess) {
    switch (mess) {
      case ServiceMessageConnectionClose():
        _repository.destroy(force: true);
        notifyRemoteClose();
      case ServiceMessageControl():
        unawaited(checkAndRequestMissingMessages());
      case ServiceMessageAcknowledge():
        _missing.handleAcknowledge(mess);
      case ServiceMessageArrayRequest(:final arrayId):
        unawaited(_missing.sendMissingMessages(arrayId));
      case ServiceMessageGone(:final arrayId):
        ermesReadRepo.handleGone(arrayId); // never answered (RFC 10.2)
      case ServiceMessageVersion():
        versionNegotiation?.onAdvert(mess);
      case ServiceMessageNewKey():
        handleNewKeyMessage(mess, _repository.cipherKey);
        notifyNewKey(mess);
    }
  }
}
