import 'dart:async';

import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';

import 'ermes_peer_key_rotator.dart';
import 'ermes_utility/observable_queue.dart';
import 'exceptions.dart';

class ErmesPeer implements IErmesPeer {
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

  final IErmesService _service;
  final IdAccountType _remotePeerId;
  final ObservableQueue<TypeOfDataExternal> _offlineQueue;
  final bool _enableEncryption;
  final ErmesPeerKeyRotator _keyRotator;

  bool _initialized = false;
  bool _disposed = false;

  late final CallbackHandler<TypeOfDataExternal, void> _onMessageHandler =
      CallbackHandler<TypeOfDataExternal, void>();
  late final CallbackHandler<IdAccountType, void>
      _onKeyExchangeCompletedHandler =
      CallbackHandler<IdAccountType, void>();
  final List<void Function()> _onDisconnectCallbacks = [];

  @override
  IdAccountType get remotePeerId => _remotePeerId;

  @override
  bool isConnected() => !_service.isClosed();

  Future<void> initialize({bool initiateKeyExchange = false}) async {
    if (_initialized || _disposed) {
      throw CoreException('ErmesPeer is already initialized or disposed');
    }

    _initialized = true;

    _service
      ..addOnMessageDataListener((data) {
        _onMessageHandler.call(data);
        _onMessageSent();
      })
      ..addOnRemoteCloseListener(() {
        for (final cb in List.of(_onDisconnectCallbacks)) {
          cb();
        }
      });

    if (_enableEncryption) {
      _keyRotator.start();
    }
  }

  @override
  Future<void> dispose({bool flushBeforeClose = true}) async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _keyRotator.dispose();

    _onDisconnectCallbacks.clear();

    _service
      ..clearOnMessageDataListeners()
      ..clearOnNewKeyListeners()
      ..clearOnRemoteCloseListeners()
      ..close();

    _onMessageHandler.clear();
    _onKeyExchangeCompletedHandler.clear();
  }

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

  @override
  void addOnDisconnectListener(void Function() callback) {
    _onDisconnectCallbacks.add(callback);
  }

  @override
  void removeOnDisconnectListener(void Function() callback) {
    _onDisconnectCallbacks.remove(callback);
  }

  void _onMessageSent() {
    if (!_enableEncryption) {
      return;
    }
    _keyRotator.onMessageSent();
  }
}
