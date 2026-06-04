import 'dart:async';

import 'package:callback_handler/callback_handler.dart';
import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';

import 'ermes_read_repo.dart';
import 'ermes_send_repo.dart';
import 'ermes_service_key_handler.dart';
import 'ermes_service_missing_messages.dart';
import 'utility.dart';

/// ErmesService - Main service for Ermes communication.
///
/// Coordinates [ErmesSendRepo] and [ErmesReadRepo], drives the
/// retransmission strategies through [MissingMessagesController], and
/// exposes the public listener surface (data, key exchange, remote close).
class ErmesService implements IErmesService {
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
  late final ErmesSendRepo ermesSendRepo;
  late final ErmesReadRepo ermesReadRepo;
  late final MissingMessagesController _missing;

  final IErmesMessageControlService? ermesMessageControlService;
  final int? missingMessagesThreshold;
  bool _isClosed = false;

  final List<void Function()> _onRemoteCloseCallbacks = [];
  late final CallbackHandler<TypeOfData, void> _onDataSendingHandler =
      CallbackHandler<TypeOfData, void>();
  late final CallbackHandler<TypeOfData, void> _onDataSentHandler =
      CallbackHandler<TypeOfData, void>();
  late final CallbackHandler<ServiceMessageNewKey, void> _onNewKeyHandler =
      CallbackHandler<ServiceMessageNewKey, void>();

  @override
  void addOnDataSendingListener(CallbackOnDataSending cb) =>
      _onDataSendingHandler.register(cb);
  @override
  void removeOnDataSendingListener(CallbackOnDataSending cb) =>
      _onDataSendingHandler.unregister(cb);
  @override
  void clearOnDataSendingListeners() => _onDataSendingHandler.clear();

  @override
  void addOnDataSentListener(CallbackOnDataSent cb) =>
      _onDataSentHandler.register(cb);
  @override
  void removeOnDataSentListener(CallbackOnDataSent cb) =>
      _onDataSentHandler.unregister(cb);
  @override
  void clearOnDataSentListeners() => _onDataSentHandler.clear();

  @override
  void addOnNewKeyListener(CallbackOnNewKey cb) =>
      _onNewKeyHandler.register(cb);
  @override
  void removeOnNewKeyListener(CallbackOnNewKey cb) =>
      _onNewKeyHandler.unregister(cb);
  @override
  void clearOnNewKeyListeners() => _onNewKeyHandler.clear();

  @override
  void addOnRemoteCloseListener(void Function() cb) =>
      _onRemoteCloseCallbacks.add(cb);
  @override
  void removeOnRemoteCloseListener(void Function() cb) =>
      _onRemoteCloseCallbacks.remove(cb);
  @override
  void clearOnRemoteCloseListeners() => _onRemoteCloseCallbacks.clear();

  @override
  void addOnMessageDataListener(CallbackOnDataArrived cb) =>
      ermesReadRepo.addOnDataArrivedListener(cb);
  @override
  void removeOnMessageDataListener(CallbackOnDataArrived cb) =>
      ermesReadRepo.removeOnDataArrivedListener(cb);
  @override
  void clearOnMessageDataListeners() =>
      ermesReadRepo.clearOnDataArrivedListeners();

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
        for (final cb in List.of(_onRemoteCloseCallbacks)) {
          cb();
        }
      case ServiceMessageControl():
        unawaited(checkAndRequestMissingMessages());
      case ServiceMessageAcknowledge():
        _missing.handleAcknowledge(mess);
      case ServiceMessageArrayRequest(:final arrayId):
        unawaited(_missing.sendMissingMessages(arrayId));
      case ServiceMessageNewKey():
        handleNewKeyMessage(mess, _repository.remotePeerId);
        _onNewKeyHandler.call(mess);
    }
  }

  @override
  void sendAcknowledge() {
    final msg = ServiceMessageAcknowledge(
      id: _idHandler.getNewId(),
      ackCurrentId: _idHandler.getCurrent(),
      ackLastReceivedId: ermesMessageControlService?.getLastReceivedId(),
    );
    ermesSendRepo.sendMessageType([MessageType.service(msg)]);
  }

  @override
  void sendNewKey({
    required CryptoAlgorithm algorithm,
    required String key,
    DateTime? start,
    DateTime? expiration,
    int? startMessage,
    int? endMessage,
  }) {
    final msg = buildNewKeyMessage(
      newId: _idHandler.getNewId(),
      algorithm: algorithm,
      key: key,
      start: start,
      expiration: expiration,
      startMessage: startMessage,
      endMessage: endMessage,
    );
    ermesSendRepo.sendMessageType([MessageType.service(msg)]);
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
    _onDataSendingHandler.call(message);
    await ermesSendRepo.send(message);
    _onDataSentHandler.call(message);
  }

  @override
  void close() {
    if (_isClosed) {
      return;
    }
    _missing.stop();
    _repository.destroy();
    _isClosed = true;
    _onDataSendingHandler.clear();
    _onDataSentHandler.clear();
    _onNewKeyHandler.clear();
    _onRemoteCloseCallbacks.clear();
  }
}
