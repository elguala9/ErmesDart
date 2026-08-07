import 'dart:async';

import 'package:iermes/iermes.dart';

import '../support/exceptions.dart';
import '../utility/observable_queue.dart';
import 'ermes_peer_key_rotator.dart';
import 'ermes_peer_listeners.dart';

/// High-level peer abstraction over an [IErmesService], adding an offline
/// send queue, optional encryption key rotation and listener management.
class ErmesPeer with ErmesPeerListeners implements IErmesPeer {
  /// Creates a peer configured with its service, remote id and optional
  /// offline-queue, encryption and key-rotation settings.
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

  /// Private constructor wiring up the service, offline queue and key rotator.
  ErmesPeer._({
    required IErmesService service,
    required IdAccountType remotePeerId,
    required int offlineQueueMaxSize,
    required bool enableEncryption,
    required int keyRotationIntervalMessages,
    required int keyRotationIntervalSeconds,
  })  : _service = service,
        _remotePeerId = remotePeerId,
        _offlineQueue =
            ObservableQueue<TypeOfDataExternal>(offlineQueueMaxSize),
        _enableEncryption = enableEncryption,
        _keyRotator = ErmesPeerKeyRotator(
          service: service,
          remotePeerId: remotePeerId,
          intervalMessages: keyRotationIntervalMessages,
          intervalSeconds: keyRotationIntervalSeconds,
        );

  /// Underlying transport service.
  final IErmesService _service;
  /// Identifier of the remote peer.
  final IdAccountType _remotePeerId;
  /// Queue holding messages sent while disconnected.
  final ObservableQueue<TypeOfDataExternal> _offlineQueue;
  /// Whether payload encryption and key rotation are enabled.
  final bool _enableEncryption;
  /// Manages periodic and message-count-based encryption key rotation.
  final ErmesPeerKeyRotator _keyRotator;

  /// Whether [initialize] has already been called.
  bool _initialized = false;
  /// Whether the peer has been disposed.
  bool _disposed = false;

  /// Identifier of the remote peer this instance communicates with.
  @override
  IdAccountType get remotePeerId => _remotePeerId;

  /// Whether the underlying service connection is currently open.
  @override
  bool isConnected() => !_service.isConnectionClosed;

  /// Wires up message/close listeners and starts key rotation; throws if the
  /// peer is already initialized or disposed.
  Future<void> initialize({bool initiateKeyExchange = false}) async {
    if (_initialized || _disposed) {
      throw CoreException('ErmesPeer is already initialized or disposed');
    }

    _initialized = true;

    _service
      ..addOnMessageDataListener((data) {
        notifyMessage(data);
        _onMessageSent();
      })
      ..addOnRemoteCloseListener(notifyDisconnect);

    if (_enableEncryption) {
      _keyRotator.start();
    }
  }

  /// Disposes the peer, stopping key rotation, closing the service and
  /// clearing all listeners.
  @override
  Future<void> dispose({bool flushBeforeClose = true}) async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _keyRotator.dispose();

    _service
      ..clearOnMessageDataListeners()
      ..clearOnNewKeyListeners()
      ..clearOnRemoteCloseListeners()
      ..close();

    disposeListeners();
  }

  /// Sends data to the peer, queuing it offline when disconnected; throws if
  /// the peer has been disposed.
  @override
  Future<void> send(TypeOfDataExternal data) async {
    if (_disposed) {
      throw CoreException('Cannot send on disposed ErmesPeer');
    }

    if (isConnected()) {
      await _service.send(data);
      _onMessageSent();
    } else {
      _offlineQueue.push(data);
    }
  }

  /// Notifies the key rotator that a message was sent when encryption is on.
  void _onMessageSent() {
    if (!_enableEncryption) {
      return;
    }
    _keyRotator.onMessageSent();
  }
}
