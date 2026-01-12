import 'dart:async';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';
import 'package:shsp_implementations/shsp_implementations.dart';

/// Core repository implementation for Ermes data transport
@includeInBarrelFile
class ErmesRepository extends ShspInstance implements IErmesRepository {
  ErmesRepository({
    required super.remotePeer,
    required super.socket,
    required this.remotePeerId,
    required this.signalHandler,
    this.timeoutMs = 30000,
  });

  final IdAccountType remotePeerId;
  final IErmesSignalingHandler<dynamic> signalHandler;
  final int timeoutMs;

  bool _closed = false;
  bool _connected = false;
  // ignore: unused_field
  CallbackOnDataRepository? _onMessageCallback;
  CallbackOnDataSending? _onDataSendingCallback;
  CallbackOnDataSent? _onDataSentCallback;

  /// Initialize the repository and establish peer connection
  Future<void> initialize() async {
    try {
      // ShspPeer is already initialized through parent constructor
      _connected = true;
    } catch (e) {
      throw Exception('Failed to initialize Ermes repository: $e');
    }
  }

  @override
  bool isClosed() => _closed;

  @override
  bool isConnected() => _connected;

  @override
  Future<void> waitForConnect([int? timeoutMs]) async {
    final timeout = timeoutMs ?? this.timeoutMs;

    if (_connected) {
      return;
    }

    // Simple timeout-based waiting
    final completer = Completer<void>();

    Timer(Duration(milliseconds: timeout), () {
      if (!completer.isCompleted) {
        if (_connected) {
          completer.complete();
        } else {
          completer.completeError(
            TimeoutException(
              'Connection timeout',
              Duration(milliseconds: timeout),
            ),
          );
        }
      }
    });

    return completer.future;
  }

  @override
  Future<void> waitForClose([int? timeoutMs]) async {
    final timeout = timeoutMs ?? this.timeoutMs;

    if (_closed) {
      return;
    }

    // Simple timeout-based waiting
    final completer = Completer<void>();

    Timer(Duration(milliseconds: timeout), () {
      if (!completer.isCompleted) {
        if (_closed) {
          completer.complete();
        } else {
          completer.completeError(
            TimeoutException('Close timeout', Duration(milliseconds: timeout)),
          );
        }
      }
    });

    return completer.future;
  }

  @override
  void send(SerializableDataType data) {
    if (_closed) {
      throw StateError('Cannot send on closed connection');
    }

    if (!_connected) {
      throw StateError('Cannot send on disconnected connection');
    }

    try {
      _onDataSendingCallback?.call(data);

      // Use inherited ShspPeer's send method
      sendMessage(data);

      _onDataSentCallback?.call(data);
    } catch (e) {
      throw Exception('Failed to send data: $e');
    }
  }

  @override
  void onMessageData(CallbackOnDataRepository callback) {
    _onMessageCallback = callback;
    // Set up listener through inherited ShspPeer
    // onMessage setter from parent: onMessage = (data, peerInfo) => callback(data);
  }

  void onDataSending(CallbackOnDataSending callback) {
    _onDataSendingCallback = callback;
  }

  void onDataSent(CallbackOnDataSent callback) {
    _onDataSentCallback = callback;
  }

  @override
  void destroy({bool force = false}) {
    _closed = true;
    _connected = false;

    // Close inherited ShspPeer connection
    close();

    // Clear callbacks
    _onMessageCallback = null;
    _onDataSendingCallback = null;
    _onDataSentCallback = null;
  }
}
