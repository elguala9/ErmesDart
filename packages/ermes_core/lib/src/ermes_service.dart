import 'dart:async';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';

import 'ermes_read_repo.dart';
import 'ermes_send_repo.dart';
import 'utility.dart';

/// Error message when requested data is not found in storage
@includeInBarrelFile
final Uint8List _dataNotFound = Uint8List.fromList('DATA NOT FOUND'.codeUnits);

/// Error message when storage is not enabled
@includeInBarrelFile
final Uint8List _noStorageEnable = Uint8List.fromList(
  'NO STORAGE ENABLE'.codeUnits,
);

/// ErmesService - Main service for Ermes communication
///
/// Main responsibilities:
/// - Coordination between ErmesSendRepo and ErmesReadRepo
/// - Automatic management of missing messages
/// - Integration with storage/caching for persistence
/// - Periodic and threshold-based control for missing requests
/// - Connection lifecycle management
/// - Public interface for end users
@includeInBarrelFile
class ErmesService implements IErmesService {
  /// ErmesService constructor
  ///
  /// Initializes all communication system components:
  /// - Transport repository
  /// - Send and receive handlers
  /// - Optional services (storage, missing control)
  /// - Automatic timers for periodic checks
  ErmesService({
    required IErmesRepository repository,
    required IIdHandlerService idHandler,
    int? maxBuffer,
    int? maxByte,
    CallbackOnDataArrived? callbackOnDataArrived,
    this.ermesStorageAndCaching,
    this.ermesMessageControlService,
    int? missingMessagesCheckIntervalMs,
    this.missingMessagesThreshold,
  }) : _repository = repository,
       _idHandler = idHandler {
    // Maximum message size validation
    final maxByteValue = maxByte ?? defaultMaxSize;
    if (maxByteValue > defaultMaxSize) {
      throw ArgumentError('maxByte cannot exceed $defaultMaxSize');
    }

    // Initialize send and receive handlers
    ermesSendRepo = ErmesSendRepo(_repository, idHandler, maxByteValue);
    ermesReadRepo = ErmesReadRepo(
      _repository,
      _handleServiceMessage,
      ermesMessageControlService,
      ErmesReadRepoOptions(
        callbackOnDataArrived: callbackOnDataArrived,
        maxBufferSize: maxBuffer ?? 100,
        // Callback for threshold control after each received message
        callbackOnMessageProcessed: checkAndRequestMissingMessages,
      ),
    );

    // Note: Storage integration can be done via addOnMessageSendingListener
    // if (ermesStorageAndCaching != null) {
    //   ermesSendRepo.addOnMessageSendingListener((message) {
    //     // Store message before sending (if needed)
    //   });
    // }

    // Automatic start of periodic missing message control if configured
    if (missingMessagesCheckIntervalMs != null &&
        ermesMessageControlService != null) {
      startMissingMessagesCheck(missingMessagesCheckIntervalMs);
    }
  }

  /// Underlying transport repository
  IErmesRepository _repository;

  /// ID handler service
  final IIdHandlerService _idHandler;

  /// Handler for message sending
  late final ErmesSendRepo ermesSendRepo;

  /// Handler for message receiving
  late final ErmesReadRepo ermesReadRepo;

  /// Optional service for message storage and caching
  final IErmesStorageAndCaching<MessageType>? ermesStorageAndCaching;

  /// Service for missing message control
  final IErmesMessageControlService? ermesMessageControlService;

  /// Timer for periodic missing message checks
  Timer? _missingMessagesInterval;

  /// Minimum threshold of missing IDs to trigger automatic requests
  final int? missingMessagesThreshold;

  /// Track if service is closed
  bool _isClosed = false;

  /// Callback handlers for user notifications
  late final CallbackHandler<TypeOfData, void> _onDataSendingHandler =
      CallbackHandler<TypeOfData, void>();
  late final CallbackHandler<TypeOfData, void> _onDataSentHandler =
      CallbackHandler<TypeOfData, void>();

  /// Register a listener for pre-send events
  @override
  void addOnDataSendingListener(CallbackOnDataSending callback) {
    _onDataSendingHandler.register(callback);
  }

  /// Remove a listener for pre-send events
  @override
  void removeOnDataSendingListener(CallbackOnDataSending callback) {
    _onDataSendingHandler.unregister(callback);
  }

  /// Clear all pre-send listeners
  @override
  void clearOnDataSendingListeners() {
    _onDataSendingHandler.clear();
  }

  /// Register a listener for post-send events
  @override
  void addOnDataSentListener(CallbackOnDataSent callback) {
    _onDataSentHandler.register(callback);
  }

  /// Remove a listener for post-send events
  @override
  void removeOnDataSentListener(CallbackOnDataSent callback) {
    _onDataSentHandler.unregister(callback);
  }

  /// Clear all post-send listeners
  @override
  void clearOnDataSentListeners() {
    _onDataSentHandler.clear();
  }

  /// Replace the transport repository
  @override
  void setRepository(IErmesRepository repository) {
    _repository = repository;
  }

  /// Check if the connection is closed
  @override
  bool isClosed() => _isClosed;

  /// Register a listener for incoming messages
  @override
  void addOnMessageDataListener(CallbackOnDataArrived callback) {
    ermesReadRepo.addOnDataArrivedListener(callback);
  }

  /// Remove a listener for incoming messages
  @override
  void removeOnMessageDataListener(CallbackOnDataArrived callback) {
    ermesReadRepo.removeOnDataArrivedListener(callback);
  }

  /// Clear all incoming message listeners
  @override
  void clearOnMessageDataListeners() {
    ermesReadRepo.clearOnDataArrivedListeners();
  }

  /// Handle service messages received from peer
  ///
  /// Service message types:
  /// - "x": forced connection close request
  /// - "c": control command (not implemented)
  /// - "a": acknowledge message with ID tracking
  /// - With arrayId: request to send specific messages
  void _handleServiceMessage(ServiceMessage mess) {
    if (mess.reason == 'x') {
      _repository.destroy(force: true);
      return;
    }
    if (mess.reason == 'c') {
      throw UnimplementedError('Not implemented');
    }
    if (mess.reason == 'a') {
      _handleAcknowledge(mess);
      return;
    }

    // If message contains an ID list, send the requested messages
    if (mess.arrayId != null) {
      _sendMissingMessages(mess.arrayId!);
    }
  }

  /// Send an acknowledge message to the peer with current ID counter and
  /// last received ID information
  void sendAcknowledge() {
    final newId = _idHandler.getNewId();
    final currentId = _idHandler.getCurrent();
    final lastReceived = ermesMessageControlService?.getLastReceivedId();
    final msg = ServiceMessage(
      id: newId,
      reason: 'a',
      ackCurrentId: currentId,
      ackLastReceivedId: lastReceived,
    );
    ermesSendRepo.sendMessageType([MessageType.service(msg)]);
  }

  /// Handle acknowledge message from peer
  ///
  /// The peer tells us:
  /// - ackCurrentId: their current outgoing message counter
  /// - ackLastReceivedId: the last message ID of ours they received
  ///
  /// If they report the last message they received, and we have sent more,
  /// we resend the missing messages to them.
  void _handleAcknowledge(ServiceMessage mess) {
    final lastAcked = mess.ackLastReceivedId;
    final ourCurrent = _idHandler.getCurrent();
    if (lastAcked == null || ermesStorageAndCaching == null) {
      return;
    }
    final gap = ourCurrent - lastAcked - 1;
    if (gap <= 0) {
      return;
    }
    final missingFromPeer = List.generate(gap, (i) => lastAcked + 1 + i);
    _sendMissingMessages(missingFromPeer);
  }

  /// Handle missing message requests (PERIODIC CONTROL ONLY)
  ///
  /// This function is called by the periodic timer and does NOT check the
  /// threshold. For threshold-based control, use
  /// checkAndRequestMissingMessages()
  ///
  /// Flow:
  /// 1. Verify that control service is available
  /// 2. Get list of missing IDs from peer
  /// 3. Send request to peer if there are missing IDs
  Future<void> _handleMissingMessages() async {
    if (ermesMessageControlService == null) {
      return;
    }

    final ids = await _otherPeerMissingMessages();
    if (ids.isNotEmpty) {
      await _sendMissingMessages(ids);
    }
  }

  /// Start periodic missing message checks (TIME-BASED PATH)
  ///
  /// Sets up a timer that calls handleMissingMessages() at regular intervals
  /// to ensure missing messages are requested even if threshold-based
  /// control doesn't activate
  void startMissingMessagesCheck(int intervalMs) {
    if (_missingMessagesInterval != null) {
      stopMissingMessagesCheck();
    }

    _missingMessagesInterval = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) async {
        try {
          await _handleMissingMessages();
        } on Exception {
          rethrow;
        }
      },
    );
  }

  /// Stop periodic missing message checks
  void stopMissingMessagesCheck() {
    _missingMessagesInterval?.cancel();
    _missingMessagesInterval = null;
  }

  /// Threshold-based missing message control (REACTIVE PATH)
  ///
  /// This function is called automatically after each received message.
  /// Checks the missing ID threshold and requests only if necessary.
  ///
  /// Flow:
  /// 1. Verify control service availability
  /// 2. Count current missing IDs
  /// 3. Compare with configured threshold
  /// 4. If threshold reached, request missing messages
  ///
  /// NOTE: This is the "separate path" for intelligent control
  Future<void> checkAndRequestMissingMessages() async {
    if (ermesMessageControlService == null) {
      return;
    }

    // Check if we've reached the missing ID threshold
    final numberOfMissingIds = ermesMessageControlService!.numberOfMissingIds();
    if (missingMessagesThreshold != null &&
        numberOfMissingIds < missingMessagesThreshold!) {
      return; // Not enough missing IDs to request
    }

    // If threshold reached or not configured, request missing messages
    await _handleMissingMessages();
  }

  /// Get the list of missing IDs that the peer should have
  Future<List<IdType>> _otherPeerMissingMessages() async {
    if (ermesMessageControlService == null) {
      return [];
    }
    return ermesMessageControlService!.idsToRequest();
  }

  /// Send messages requested by the peer
  ///
  /// For each requested ID:
  /// 1. Check if storage is enabled
  /// 2. Search for message in storage
  /// 3. Send the message or an error message
  Future<void> _sendMissingMessages(List<IdType> arrayId) async {
    final items = <MessageType>[];
    for (final id in arrayId) {
      // If storage is not enabled, send error message
      if (ermesStorageAndCaching == null) {
        items.add(
          MessageType.data(createMessageDataErmes(_noStorageEnable, id)),
        );
        continue;
      }

      // Search for message in storage
      final mess = await ermesStorageAndCaching!.retrieve(id);
      // If message is not found, send error message
      if (mess == null) {
        items.add(MessageType.data(createMessageDataErmes(_dataNotFound, id)));
        continue;
      }
      items.add(mess);
    }

    if (items.isEmpty) {
      throw Exception('Error during sendMissingBaseMessage, empty items array');
    }

    // Send all messages together
    ermesSendRepo.sendMessageType(items);
  }

  /// Main public method for sending user data
  ///
  /// Handles pre/post send callbacks and delegates to ErmesSendRepo
  @override
  void send(TypeOfData message) {
    // Invoke all pre-send listeners
    _onDataSendingHandler.call(message);

    // Actual sending
    ermesSendRepo.send(message);

    // Invoke all post-send listeners
    _onDataSentHandler.call(message);
  }

  /// Close the connection and stop all processes
  @override
  void close() {
    if (_isClosed) {
      return;
    }

    stopMissingMessagesCheck();
    _repository.destroy();
    _isClosed = true;

    // Cleanup handlers
    _onDataSendingHandler.clear();
    _onDataSentHandler.clear();
  }


  bool onClose(void Function() closeCallback) {
    // TODO: implement onClose
    throw UnimplementedError();
  }

  bool onClosing(void Function() closingCallback) {
    // TODO: implement onClosing
    throw UnimplementedError();
  }

  bool onOpen(void Function() openCallback) {
    // TODO: implement onOpen
    throw UnimplementedError();
  }
  
  @override
  bool isClosing() => _repository.isClosing();
  
  @override
  bool isOpen() => _repository.isOpen();
}
