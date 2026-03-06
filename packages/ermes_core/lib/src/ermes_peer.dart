import 'dart:async';
import 'dart:math';


import 'package:callback_handler/callback_handler.dart';
import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

import 'ermes_service.dart';
import 'ermes_utility/observable_queue.dart';

/// High-level facade for simplified peer-to-peer messaging
///
/// ErmesPeer encapsulates the complexity of managing peer connections,
/// including:
/// - Connection lifecycle (initialize, reconnect, dispose)
/// - Message sending with offline queueing
/// - ECDH-based key exchange for symmetric encryption
/// - Automatic offline queue flushing on reconnection
/// - Message arrival and connection state notifications
///
/// Usage:
/// ```dart
/// final peer = await ErmesPeerFactory.create(config);
/// await peer.initialize(initiateKeyExchange: true);
///
/// peer.addOnMessageListener((data) => print('Got: $data'));
/// peer.send(myMessage);
///
/// await peer.dispose();
/// ```

class ErmesPeer implements IErmesPeer {
  // Factory constructor for creating instances
  factory ErmesPeer.create({
    required IErmesService service,
    required IdAccountType remotePeerId,
    int offlineQueueMaxSize = 100,
    bool enableEncryption = true,
    int keyRotationIntervalMessages = 1000,
    int keyRotationIntervalSeconds = 3600,
  }) =>
      ErmesPeer._(
        service: service,
        remotePeerId: remotePeerId,
        offlineQueueMaxSize: offlineQueueMaxSize,
        enableEncryption: enableEncryption,
        keyRotationIntervalMessages: keyRotationIntervalMessages,
        keyRotationIntervalSeconds: keyRotationIntervalSeconds,
      );

  // Private constructor - use factory ErmesPeer.create()
  ErmesPeer._({
    required IErmesService service,
    required IdAccountType remotePeerId,
    int offlineQueueMaxSize = 100,
    bool enableEncryption = true,
    int keyRotationIntervalMessages = 1000,
    int keyRotationIntervalSeconds = 3600,
  })  : _service = service,
        _remotePeerId = remotePeerId,
        _offlineQueue =
            ObservableQueue<TypeOfDataExternal>(offlineQueueMaxSize),
        _enableEncryption = enableEncryption,
        _keyRotationIntervalMessages = keyRotationIntervalMessages,
        _keyRotationIntervalSeconds = keyRotationIntervalSeconds;

  // Immutable dependencies
  final IErmesService _service;
  final IdAccountType _remotePeerId;
  final ObservableQueue<TypeOfDataExternal> _offlineQueue;

  // Encryption and key rotation configuration
  final bool _enableEncryption;
  final int _keyRotationIntervalMessages;
  final int _keyRotationIntervalSeconds;

  // State tracking
  bool _initialized = false;
  bool _disposed = false;

  // Key rotation state
  Timer? _keyRotationTimer;
  int _messageCountSinceRotation = 0;

  // Callback handlers
  late final CallbackHandler<TypeOfDataExternal, void> _onMessageHandler =
      CallbackHandler<TypeOfDataExternal, void>();
  late final CallbackHandler<IdAccountType, void>
      _onKeyExchangeCompletedHandler =
      CallbackHandler<IdAccountType, void>();

  @override
  IdAccountType get remotePeerId => _remotePeerId;

  bool isConnected() => !_service.isClosed();

  // ========================================================================
  // Lifecycle Methods
  // ========================================================================

  Future<void> initialize({bool initiateKeyExchange = false}) async {
    if (_initialized || _disposed) {
      throw StateError('ErmesPeer is already initialized or disposed');
    }

    _initialized = true;

    // Register listener for incoming messages
    _service.addOnMessageDataListener((data) {
      _onMessageHandler.call(data);
      _onMessageSent();
    });


    // Start key rotation timer if encryption is enabled
    if (_enableEncryption) {
      _startKeyRotationTimer();
    }

  }

  @override
  Future<void> dispose({bool flushBeforeClose = true}) async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    // Cancel key rotation timer
    _keyRotationTimer?.cancel();
    _keyRotationTimer = null;

    // Clean up service listeners
    _service
      ..clearOnMessageDataListeners()
      ..clearOnNewKeyListeners()
      ..close();

    // Clear all local listeners
    _onMessageHandler.clear();
    _onKeyExchangeCompletedHandler.clear();
  }

  // ========================================================================
  // Messaging Methods
  // ========================================================================

  @override
  Future<void> send(TypeOfDataExternal data) async {
    if (_disposed) {
      throw StateError('Cannot send on disposed ErmesPeer');
    }

    if (isConnected()) {
      await _service.send(data);
      _onMessageSent();
    } else {
      _offlineQueue.push(data);
    }
  }

  @override
  void addOnMessageListener(CallbackOnDataArrived callback) {
    _onMessageHandler.register(callback);
  }

  @override
  void removeOnMessageListener(CallbackOnDataArrived callback) {
    _onMessageHandler.unregister(callback);
  }

  @override
  void clearOnMessageListeners() {
    _onMessageHandler.clear();
  }

  


  /// Start the key rotation timer
  void _startKeyRotationTimer() {
    _keyRotationTimer = Timer.periodic(
      Duration(seconds: _keyRotationIntervalSeconds),
      (_) => _checkKeyRotation(),
    );
  }

  /// Called when a message is sent to track rotation interval
  void _onMessageSent() {
    if (!_enableEncryption) {
      return;
    }

    _messageCountSinceRotation++;

    if (_messageCountSinceRotation >= _keyRotationIntervalMessages) {
      _checkKeyRotation();
    }
  }

  /// Check and perform key rotation if needed
  void _checkKeyRotation() {
    if (_disposed || !_enableEncryption) {
      return;
    }

    _messageCountSinceRotation = 0;

    // Get the peer cipher from the handler
    final cipherHandler = ErmesPeerCipherHandler();
    final peerCipher = cipherHandler.get(_remotePeerId);

    if (peerCipher == null) {
      return;
    }

    // Generate new random AES key (32 bytes = 256 bits)
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final newKeyHex =
        keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // Create new AES cipher
    final newCipher = generateSymmetric(newKeyHex, SymmetricAlgorithm.aes);

    // Add to handler and send to peer
    (peerCipher as IErmesPeerCipher).addEncryptCipher(newCipher);
    (_service as ErmesService).sendNewKey(
      algorithm: SymmetricAlgorithm.aes,
      key: newKeyHex,
    );
  }

}
