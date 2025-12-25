import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

/// Implementation of IErmesConnection that manages peer connections through signaling
/// and handles repository creation and reconnection
class ErmesConnection implements IErmesConnection {
  ErmesConnection(
    this._signalingHandler,
    this._factory,
    this._repository,
    this._connectionId,
  );
  final IErmesSignalingHandler<dynamic> _signalingHandler;
  final IErmesFactory<dynamic> _factory;
  IErmesRepository _repository;
  final IdPeer _connectionId;
  CloseCallback? _closeCallback;
  bool _isConnectionClosed = false;
  bool _isReconnecting = false;
  static const int _maxReconnectAttempts = 3;
  int _reconnectAttempts = 0;

  @override
  IErmesRepository getIErmesRepository() => _repository;

  @override
  Future<IErmesRepository> reconnect() async {
    if (_isReconnecting) {
      throw Exception('Reconnection already in progress');
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      throw Exception('Maximum reconnection attempts exceeded');
    }

    _isReconnecting = true;
    _reconnectAttempts++;

    await _signalingHandler.clearConnection(_connectionId);

    _repository =
        await _factory.createRepository(_connectionId, _signalingHandler);
    _reconnectAttempts = 0;
    _isReconnecting = false;

    return _repository;
  }

  @override
  Future<void> close() async {
    if (_isConnectionClosed) return;

    _isConnectionClosed = true;
    await _signalingHandler.clearConnection(_connectionId);
    _closeCallback?.call();
  }

  @override
  void setCloseCallback(CloseCallback callback) {
    _closeCallback = callback;
  }

  @override
  Future<bool> isClosed() async => _isConnectionClosed;

  @override
  Future<bool> ping() async {
    if (_isConnectionClosed) return false;
    return _signalingHandler.isSocketReady(_connectionId);
  }

  @override
  IdPeer getIdConnection() => _connectionId;

  @override
  Future<void> saveState() async {
    throw UnimplementedError(
      'ErmesConnection.saveState() is not implemented. This method should persist the connection state to storage but is currently a placeholder.',
    );
  }

  @override
  Future<void> loadState() async {
    throw UnimplementedError(
      'ErmesConnection.loadState() is not implemented. This method should restore the connection state from storage but is currently a placeholder.',
    );
  }

  @override
  Future<void> destroyConnection({bool close = true}) async {
    if (close) await this.close();
    _closeCallback = null;
    await _signalingHandler.softClearConnection(_connectionId);
  }
}
