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
///
/// Chunking/fragmentation of outbound data and reassembly of inbound data are
/// delegated to the send/read repositories; this class owns the cross-cutting
/// flow (send, service-message handling, missing-message checks). See
/// `docs/flows/message_lifecycle.md` for the end-to-end pipeline.
class ErmesService
    with ErmesServiceListeners, ErmesServiceSenders
    implements IErmesService {
  /// Creates the service, wiring the send/read repositories and the
  /// missing-message controller; throws if [maxByte] exceeds the allowed max.
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

  /// Transport repository backing this service.
  IErmesRepository _repository;
  /// Handler assigning unique message ids.
  final IIdHandlerService _idHandler;
  /// Repository responsible for sending and fragmenting outbound messages.
  @override
  late final ErmesSendRepo ermesSendRepo;
  /// Repository responsible for decoding and reassembling inbound messages.
  @override
  late final ErmesReadRepo ermesReadRepo;
  /// Controller driving missing-message detection and retransmission.
  late final MissingMessagesController _missing;

  /// Optional message-control service tracking received message ids.
  @override
  final IErmesMessageControlService? ermesMessageControlService;
  /// Threshold of missing messages that triggers a resend request.
  final int? missingMessagesThreshold;
  /// Whether the service has been explicitly closed.
  bool _isClosed = false;

  /// Handler assigning unique ids to outgoing messages.
  @override
  IIdHandlerService get idHandler => _idHandler;

  /// Replaces the underlying transport repository, e.g. after reconnection.
  @override
  void setRepository(IErmesRepository repository) {
    _repository = repository;
  }

  /// Whether the service or its repository is closed.
  @override
  bool get isConnectionClosed => _isClosed || _repository.isConnectionClosed;

  /// Whether the underlying connection is closing.
  @override
  bool isClosing() => _repository.isClosing();

  /// Whether the underlying connection is open.
  @override
  bool isOpen() => _repository.isOpen();

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
      case ServiceMessageNewKey():
        handleNewKeyMessage(mess, _repository.remotePeerId);
        notifyNewKey(mess);
    }
  }

  /// Starts periodic missing-message checks at the given interval.
  @override
  void startMissingMessagesCheck(int intervalMs) => _missing.start(intervalMs);

  /// Stops periodic missing-message checks.
  @override
  void stopMissingMessagesCheck() => _missing.stop();

  /// Checks for missing messages and requests their retransmission.
  @override
  Future<void> checkAndRequestMissingMessages() =>
      _missing.checkAndRequestMissingMessages();

  /// Sends application data, notifying send listeners before and after.
  @override
  Future<void> send(TypeOfData message) async {
    notifyDataSending(message);
    await ermesSendRepo.send(message);
    notifyDataSent(message);
  }

  /// Closes the service, stopping checks, destroying the repository and
  /// clearing listeners; idempotent.
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
