import 'dart:async';

import 'package:iermes/iermes.dart';

import '../repository/ermes_read_repo.dart';
import '../repository/ermes_send_repo.dart';
import '../utility/utility.dart';
import 'ermes_service_key_handler.dart';
import 'ermes_service_listeners.dart';
import 'ermes_service_missing_messages.dart';
import 'ermes_service_senders.dart';
import 'ermes_service_versioning.dart';

part 'ermes_service_dispatch.dart';

/// ErmesService - coordinates [ErmesSendRepo] and [ErmesReadRepo], drives
/// retransmission via [MissingMessagesController], version negotiation via
/// [ErmesServiceVersioning] and the listener surface of
/// [ErmesServiceListeners]. See `docs/flows/message_lifecycle.md`.
class ErmesService
    with ErmesServiceListeners, ErmesServiceSenders, ErmesServiceVersioning
    implements IErmesService {
  /// Wires the send/read repositories and the missing-message controller;
  /// throws if [maxByte] is too large. A non-null [versionNegotiation]
  /// enables RFC 7.1 version negotiation.
  ErmesService({
    required IErmesRepository repository,
    required IIdHandlerService idHandler,
    int? maxBuffer,
    int? maxByte,
    CallbackOnDataArrived? callbackOnDataArrived,
    this.ermesMessageControlService,
    int? missingMessagesCheckIntervalMs,
    this.missingMessagesThreshold,
    ErmesVersionNegotiationOptions? versionNegotiation,
  }) : _repository = repository,
       _idHandler = idHandler {
    final maxByteValue = maxByte ?? defaultMaxSize;
    if (maxByteValue > defaultMaxSize) {
      throw ArgumentError('maxByte cannot exceed $defaultMaxSize');
    }

    ermesSendRepo = ErmesSendRepo(_repository, idHandler, maxByteValue);
    final negotiation = createVersionNegotiation(versionNegotiation);
    ermesReadRepo = ErmesReadRepo(
      _repository,
      _handleServiceMessage,
      ermesMessageControlService,
      ErmesReadRepoOptions(
        callbackOnDataArrived: callbackOnDataArrived,
        maxBufferSize: maxBuffer ?? 100,
        maxMessageSize: maxByte,
        // Fire-and-forget: never stall inbound on an outbound request.
        callbackOnMessageProcessed: () async =>
            unawaited(checkAndRequestMissingMessages()),
        versionNegotiation: negotiation,
      ),
    );
    _missing = _createMissingController();
    if (missingMessagesCheckIntervalMs != null &&
        ermesMessageControlService != null) {
      _missing.start(missingMessagesCheckIntervalMs);
    }
    startVersionNegotiation();
  }

  /// Transport repository backing this service.
  IErmesRepository _repository;

  /// Cipher-handler key of this service's Connection (peer + family).
  String get cipherKey => _repository.cipherKey;
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
  void setRepository(IErmesRepository repository) => _repository = repository;

  /// Whether the service or its repository is closed.
  @override
  bool get isConnectionClosed => _isClosed || _repository.isConnectionClosed;

  /// Whether the underlying connection is closing.
  @override
  bool isClosing() => _repository.isClosing();

  /// Whether the underlying connection is open.
  @override
  bool isOpen() => _repository.isOpen();

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

  /// Sends application data, notifying send listeners before and after;
  /// held until version negotiation completes, throws if it failed.
  @override
  Future<void> send(TypeOfData message) async {
    if (versionNegotiation case final negotiation?) {
      await negotiation.ready;
    }
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
    versionNegotiation?.dispose();
    _repository.destroy();
    _isClosed = true;
    clearAllListeners();
  }
}
