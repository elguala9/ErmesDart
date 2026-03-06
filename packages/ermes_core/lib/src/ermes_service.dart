import 'dart:async';
import 'dart:typed_data';


import 'package:callback_handler/callback_handler.dart';
import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

import 'ermes_read_repo.dart';
import 'ermes_send_repo.dart';
import 'utility.dart';

/// Error message when requested data is not found in storage

final Uint8List _dataNotFound = Uint8List.fromList('DATA NOT FOUND'.codeUnits);

/// Error message when storage is not enabled

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
  late final CallbackHandler<ServiceMessageNewKey, void> _onNewKeyHandler =
      CallbackHandler<ServiceMessageNewKey, void>();

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

  /// Register a listener for new key messages
  @override
  void addOnNewKeyListener(CallbackOnNewKey callback) {
    _onNewKeyHandler.register(callback);
  }

  /// Remove a listener for new key messages
  @override
  void removeOnNewKeyListener(CallbackOnNewKey callback) {
    _onNewKeyHandler.unregister(callback);
  }

  /// Clear all new key listeners
  @override
  void clearOnNewKeyListeners() {
    _onNewKeyHandler.clear();
  }

  /// Replace the transport repository
  @override
  void setRepository(IErmesRepository repository) {
    _repository = repository;
  }

  /// Check if the connection is closed
  @override
  bool isClosed() => _isClosed || _repository.isClosed();

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
  void _handleServiceMessage(ServiceMessage mess) {
    switch (mess) {
      case ServiceMessageConnectionClose():
        _repository.destroy(force: true);
      case ServiceMessageControl():
        throw UnimplementedError('Not implemented');
      case ServiceMessageAcknowledge():
        _handleAcknowledge(mess);
      case ServiceMessageArrayRequest(:final arrayId):
        _sendMissingMessages(arrayId);
      case ServiceMessageNewKey():
        _handleNewKey(mess);
    }
  }

  /// Send an acknowledge message to the peer with current ID counter and
  /// last received ID information
  @override
  void sendAcknowledge() {
    final newId = _idHandler.getNewId();
    final currentId = _idHandler.getCurrent();
    final lastReceived = ermesMessageControlService?.getLastReceivedId();
    final msg = ServiceMessageAcknowledge(
      id: newId,
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
  void _handleAcknowledge(ServiceMessageAcknowledge mess) {
    final lastAcked = mess.ackLastReceivedId;
    final ourCurrent = _idHandler.getCurrent();
    if (lastAcked == null) {
      return;
    }
    final gap = ourCurrent - lastAcked - 1;
    if (gap <= 0) {
      return;
    }
    final missingFromPeer = List.generate(gap, (i) => lastAcked + 1 + i);
    _sendMissingMessages(missingFromPeer);
  }

  /// Handle new key exchange message from peer
  ///
  /// Receives key material with algorithm, validity windows, and message
  /// ranges. Registers the key with ErmesPeerCipherHandler and invokes
  /// registered callbacks to notify listeners of the new key.
  void _handleNewKey(ServiceMessageNewKey mess) {
    try {
      // Get or create the peer cipher for this remote peer
      final handler = ErmesPeerCipherHandler();
      final peerId = _repository.remotePeerId;
      var peerCipher = handler.get(peerId);

      if (peerCipher == null) {
        // Create new peer cipher if it doesn't exist
        peerCipher = createErmesPeerCipher() as ErmesPeerCipher;
        handler.set(peerId, peerCipher);
      }

      // Create symmetric cipher from the key material
      final symmetricCipher = generateSymmetric(
        mess.key,
        mess.algorithm,
        mess.expiration,
      );

      // Add as decryption cipher
      // (we'll decrypt messages from this peer using this key)
      peerCipher.addDecryptCipher(symmetricCipher);
    } on Exception catch (e) {
      // Log error but continue - key exchange should not break communication
      // ignore: avoid_print
      print('Error handling new key: $e');
    }

    // Notify registered listeners
    _onNewKeyHandler.call(mess);
  }

  /// Send a new key exchange message to the peer
  ///
  /// Distributes encryption key material with validity windows
  @override
  void sendNewKey({
    required CryptoAlgorithm algorithm,
    required String key,
    DateTime? start,
    DateTime? expiration,
    int? startMessage,
    int? endMessage,
  }) {
    final newId = _idHandler.getNewId();
    final msg = ServiceMessageNewKey(
      id: newId,
      algorithm: algorithm,
      key: key,
      start: start,
      expiration: expiration,
      startMessage: startMessage,
      endMessage: endMessage,
    );
    ermesSendRepo.sendMessageType([MessageType.service(msg)]);
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
  @override
  void startMissingMessagesCheck(int intervalMs) {
    if (_missingMessagesInterval != null) {
      stopMissingMessagesCheck();
    }

    _missingMessagesInterval = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => _handleMissingMessages(),
    );
  }

  /// Stop periodic missing message checks
  @override
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
  @override
  Future<void> checkAndRequestMissingMessages() async {
    if (ermesMessageControlService == null) {
      return;
    }

    // Check if we've reached the missing ID threshold
    final numberOfMissingIds =
        ermesMessageControlService!.numberOfMissingIds();
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
  Future<void> _sendMissingMessages(List<IdType> arrayId) async {
    for (final id in arrayId) {
      await ermesSendRepo.sendAgain(id);
    }
  }

  /// Main public method for sending user data
  ///
  /// Handles pre/post send callbacks and delegates to ErmesSendRepo
  @override
  Future<void> send(TypeOfData message) async {
    // Invoke all pre-send listeners
    _onDataSendingHandler.call(message);

    // Actual sending (with storage)
    await ermesSendRepo.send(message);

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
    _onNewKeyHandler.clear();
  }
  
  @override
  bool isClosing() => _repository.isClosing();
  
  @override
  bool isOpen() => _repository.isOpen();
}
