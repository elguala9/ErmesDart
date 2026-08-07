
import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../support/exceptions.dart';

/// Implementation of IErmesConnection that manages peer connections through
/// signaling and handles repository management and reconnection

class ErmesConnection implements IErmesConnection {
  /// Creates a connection bound to the given signaling handler, repository
  /// and connection identifier.
  ErmesConnection(
    this._signalingHandler,
    this._repository,
    this._connectionId,
  );
  /// Signaling handler used to establish and tear down the connection.
  final IErmesSignalingHandler<IShspSocket> _signalingHandler;
  /// Repository associated with this connection.
  final IErmesRepository _repository;
  /// Unique identifier of the peer this connection targets.
  final IdPeer _connectionId;

  /// Callback handler for close events
  late final CallbackHandler<void, void> _closeHandler =
      CallbackHandler<void, void>();

  /// Maximum number of reconnection attempts before giving up.
  static const int _maxReconnectAttempts = 3;
  /// Number of reconnection attempts performed so far.
  int _reconnectAttempts = 0;

  /// Returns the repository associated with this connection.
  @override
  IErmesRepository getIErmesRepository() => _repository;

  /// Re-establishes the connection, clearing the previous signaling state,
  /// throwing when the maximum reconnection attempts are exceeded.
  @override
  Future<IErmesRepository> connect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      throw CoreException(
        'Maximum reconnection attempts ($_maxReconnectAttempts) exceeded',
      );
    }

    _reconnectAttempts++;

    await _signalingHandler.clearConnection(_connectionId);

    await Future<void>.delayed(const Duration(milliseconds: 100));

    _reconnectAttempts = 0;
    return _repository;
  }

  /// Resets the reconnection attempt counter back to zero.
  @override
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }


  /// Returns the identifier of the peer this connection targets.
  @override
  IdPeer getIdConnection() => _connectionId;



  /// Tears down the connection, clearing close listeners and releasing the
  /// underlying signaling connection.
  @override
  Future<void> destroyConnection({bool close = true}) async {

    // Clear all close listeners
    _closeHandler.clear();
    await _signalingHandler.softClearConnection(_connectionId);
  }
}
