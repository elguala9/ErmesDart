import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:callback_handler/callback_handler.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

import 'models/connection_state.dart';

/// Implementation of IErmesConnection that manages peer connections through
/// signaling and handles repository management and reconnection
@includeInBarrelFile
class ErmesConnection implements IErmesConnection {
  ErmesConnection(this._signalingHandler, this._repository, this._connectionId);
  final IErmesSignalingHandler<dynamic> _signalingHandler;
  final IErmesRepository _repository;
  final IdPeer _connectionId;

  /// Callback handler for close events
  late final CallbackHandler<void, void> _closeHandler =
      CallbackHandler<void, void>();

  bool _isConnectionClosed = false;
  static const int _maxReconnectAttempts = 3;
  int _reconnectAttempts = 0;
  ConnectionState? _savedState;

  @override
  IErmesRepository getIErmesRepository() => _repository;

  @override
  Future<IErmesRepository> reconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      throw Exception(
        'Maximum reconnection attempts ($_maxReconnectAttempts) exceeded',
      );
    }

    _reconnectAttempts++;

    try {
      // Step 1: Save current state before attempting reconnection
      await saveState();

      // Step 2: Clear old connection from signaling handler
      await _signalingHandler.clearConnection(_connectionId);

      // Step 3: Wait for network transmission
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Step 4: On success, reset attempt counter
      _reconnectAttempts = 0;

      return _repository;
    } catch (e) {
      // On failure, keep state for next attempt
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    if (_isConnectionClosed) {
      return;
    }

    _isConnectionClosed = true;
    await _signalingHandler.clearConnection(_connectionId);

    // Invoke all registered close listeners
    _closeHandler.call(null);
  }

  @override
  void setCloseCallback(CloseCallback callback) {
    // Clear previous callbacks and register new one (legacy API behavior)
    _closeHandler.clear();
    _closeHandler.register((_) => callback());
  }

  /// Register a listener for close events
  void addCloseListener(CloseCallback callback) {
    _closeHandler.register((_) => callback());
  }

  /// Clear all close listeners
  void clearCloseListeners() {
    _closeHandler.clear();
  }

  @override
  Future<bool> isClosed() async => _isConnectionClosed;

  @override
  Future<bool> ping() async {
    if (_isConnectionClosed) {
      return false;
    }
    return _signalingHandler.isSocketReady(_connectionId);
  }

  @override
  IdPeer getIdConnection() => _connectionId;

  @override
  Future<void> saveState() async {
    _savedState = ConnectionState(
      connectionId: _connectionId,
      remotePeerId: _connectionId,
      reconnectAttempts: _reconnectAttempts,
      isClosed: _isConnectionClosed,
      lastActiveTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> loadState() async {
    if (_savedState == null) {
      throw StateError('No saved state available to load');
    }

    // Validate state is not too old (24 hours)
    final now = DateTime.now().millisecondsSinceEpoch;
    const maxAge = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
    final stateAge = now - _savedState!.lastActiveTimestamp;

    if (stateAge > maxAge) {
      throw StateError(
        'Saved state is too old (${stateAge}ms), cannot restore',
      );
    }

    // Restore state
    _reconnectAttempts = _savedState!.reconnectAttempts;
    _isConnectionClosed = _savedState!.isClosed;
  }

  @override
  Future<void> destroyConnection({bool close = true}) async {
    if (close) {
      await this.close();
    }
    // Clear all close listeners
    _closeHandler.clear();
    await _signalingHandler.softClearConnection(_connectionId);
  }
}
