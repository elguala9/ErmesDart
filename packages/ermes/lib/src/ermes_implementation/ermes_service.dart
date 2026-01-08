import 'dart:async';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

import '../utility.dart';
import 'ermes_read_repo.dart';
import 'ermes_send_repo.dart';

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
  }) : _repository = repository {
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

    // Connect storage with send callback if available
    if (ermesStorageAndCaching != null) {
      ermesSendRepo.setCallbackOnDataSending(
        (message) => ermesStorageAndCaching!.store(message),
      );
    }

    // Automatic start of periodic missing message control if configured
    if (missingMessagesCheckIntervalMs != null &&
        ermesMessageControlService != null) {
      startMissingMessagesCheck(missingMessagesCheckIntervalMs);
    }
  }

  /// Underlying transport repository
  IErmesRepository _repository;

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

  // Local callbacks for user notifications
  /// Callback called before sending a message
  CallbackOnDataSending? _callbackOnDataSending;

  /// Callback called after sending a message
  CallbackOnDataSent? _callbackOnDataSended;

  /// Set callback for pre-send notification
  @override
  void onDataSending(CallbackOnDataSending callback) {
    _callbackOnDataSending = callback;
  }

  /// Set callback for post-send notification
  @override
  void onDataSent(CallbackOnDataSent callback) {
    _callbackOnDataSended = callback;
  }

  /// Replace the transport repository
  @override
  void setRepository(IErmesRepository repository) {
    _repository = repository;
  }

  /// Check if the connection is closed
  @override
  bool isClosed() => _repository.isClosed();

  /// Set the callback for incoming messages
  @override
  void onMessage(CallbackOnDataArrived messageCallback) {
    ermesReadRepo.setMessageDataCallback(messageCallback);
  }

  /// Handle service messages received from peer
  ///
  /// Service message types:
  /// - "x": forced connection close request
  /// - "c": control command (not implemented)
  /// - With arrayId: request to send specific messages
  void _handleServiceMessage(ServiceMessage mess) {
    if (mess.reason == 'x') {
      _repository.destroy(force: true);
      return;
    }
    if (mess.reason == 'c') {
      throw UnimplementedError('Not implemented');
    }

    // If message contains an ID list, send the requested messages
    if (mess.arrayId != null) {
      _sendMissingMessages(mess.arrayId!);
    }
  }

  /// Handle missing message requests (PERIODIC CONTROL ONLY)
  ///
  /// This function is called by the periodic timer and does NOT check the threshold.
  /// For threshold-based control, use checkAndRequestMissingMessages()
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
        } catch (error) {
          // ignore: avoid_print
          print('Error in periodic handleMissingMessages: $error');
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
    // Pre-send callback
    if (_callbackOnDataSending != null) {
      _callbackOnDataSending!(message);
    }

    // Actual sending
    ermesSendRepo.send(message);

    // Post-send callback
    if (_callbackOnDataSended != null) {
      _callbackOnDataSended!(message);
    }
  }

  /// Close the connection and stop all processes
  @override
  void close() {
    stopMissingMessagesCheck();
    _repository.destroy();
  }

  /// Check if the connection is active
  @override
  bool isConnected() => _repository.isConnected();

  /// Wait for the connection to be established
  @override
  Future<void> waitForConnect([int? timeoutMs]) =>
      _repository.waitForConnect(timeoutMs);

  /// Wait for the connection to close
  @override
  Future<void> waitForClose([int? timeoutMs]) =>
      _repository.waitForClose(timeoutMs);
}
