import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:callback_handler/callback_handler.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

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

  @override
  IErmesRepository getIErmesRepository() => _repository;

  @override
  Future<IErmesRepository> reconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      throw Exception('Maximum reconnection attempts exceeded');
    }

    _reconnectAttempts++;
    await _signalingHandler.clearConnection(_connectionId);

    // TODO: Implement actual repository reconnection logic
    // This would involve creating a new repository with updated peer info
    // from the signaling handler
    _reconnectAttempts = 0;

    return _repository;
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
    throw UnimplementedError(
      'ErmesConnection.saveState() is not implemented. This method should '
      'persist the connection state to storage but is currently a placeholder.',
    );
  }

  @override
  Future<void> loadState() async {
    throw UnimplementedError(
      'ErmesConnection.loadState() is not implemented. This method '
      'should restore the connection state from storage but is currently '
      'a placeholder.',
    );
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
