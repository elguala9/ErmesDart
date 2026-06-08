import 'dart:async';

import 'package:iermes/iermes.dart';

import 'ermes_read_repo.dart';
import 'ermes_send_repo.dart';
import 'ermes_service_key_handler.dart';
import 'ermes_service_listeners.dart';
import 'ermes_service_missing_messages.dart';
import 'ermes_service_senders.dart';
import 'utility.dart';

/// ErmesService - Main service for Ermes communication.
///
/// Coordinates [ErmesSendRepo] and [ErmesReadRepo], drives the
/// retransmission strategies through [MissingMessagesController], and
/// exposes the public listener surface (data, key exchange, remote close)
/// via [ErmesServiceListeners].
class ErmesService
    with ErmesServiceListeners, ErmesServiceSenders
    implements IErmesService {
  ErmesService({
    required IErmesRepository repository,
    required IIdHandlerService idHandler,
    int? maxBuffer,
    int? maxByte,
    CallbackOnDataArrived? callbackOnDataArrived,
    this.ermesMessageControlService,
    int? missingMessagesCheckIntervalMs,
    this.missingMessagesThreshold,
  }) : _repository = repository,
       _idHandler = idHandler {
    final maxByteValue = maxByte ?? defaultMaxSize;
    if (maxByteValue > defaultMaxSize) {
      throw ArgumentError('maxByte cannot exceed $defaultMaxSize');
    }

    ermesSendRepo = ErmesSendRepo(_repository, idHandler, maxByteValue);
    ermesReadRepo = ErmesReadRepo(
      _repository,
      _handleServiceMessage,
      ermesMessageControlService,
      ErmesReadRepoOptions(
        callbackOnDataArrived: callbackOnDataArrived,
        maxBufferSize: maxBuffer ?? 100,
        maxMessageSize: maxByte,
        callbackOnMessageProcessed: checkAndRequestMissingMessages,
      ),
    );

    _missing = MissingMessagesController(
      controlService: ermesMessageControlService,
      sendRepo: ermesSendRepo,
      idHandler: _idHandler,
      threshold: missingMessagesThreshold,
    );

    if (missingMessagesCheckIntervalMs != null &&
        ermesMessageControlService != null) {
      _missing.start(missingMessagesCheckIntervalMs);
    }
  }

  IErmesRepository _repository;
  final IIdHandlerService _idHandler;
  @override
  late final ErmesSendRepo ermesSendRepo;
  @override
  late final ErmesReadRepo ermesReadRepo;
  late final MissingMessagesController _missing;

  @override
  final IErmesMessageControlService? ermesMessageControlService;
  final int? missingMessagesThreshold;
  bool _isClosed = false;

  @override
  IIdHandlerService get idHandler => _idHandler;

  @override
  void setRepository(IErmesRepository repository) {
    _repository = repository;
  }

  @override
  bool isClosed() => _isClosed || _repository.isClosed();

  @override
  bool isClosing() => _repository.isClosing();

  @override
  bool isOpen() => _repository.isOpen();

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
      case ServiceMessageNewKey():
        handleNewKeyMessage(mess, _repository.remotePeerId);
        notifyNewKey(mess);
    }
  }

  @override
  void startMissingMessagesCheck(int intervalMs) => _missing.start(intervalMs);

  @override
  void stopMissingMessagesCheck() => _missing.stop();

  @override
  Future<void> checkAndRequestMissingMessages() =>
      _missing.checkAndRequestMissingMessages();

  @override
  Future<void> send(TypeOfData message) async {
    notifyDataSending(message);
    await ermesSendRepo.send(message);
    notifyDataSent(message);
  }

  @override
  void close() {
    if (_isClosed) {
      return;
    }
    _missing.stop();
    _repository.destroy();
    _isClosed = true;
    clearAllListeners();
  }
}
