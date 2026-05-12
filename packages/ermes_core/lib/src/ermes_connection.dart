
import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'exceptions.dart';

/// Implementation of IErmesConnection that manages peer connections through
/// signaling and handles repository management and reconnection

class ErmesConnection implements IErmesConnection {
  ErmesConnection(
    this._signalingHandler,
    this._repository,
    this._connectionId,
  );
  final IErmesSignalingHandler<IShspSocket> _signalingHandler;
  final IErmesRepository _repository;
  final IdPeer _connectionId;

  /// Callback handler for close events
  late final CallbackHandler<void, void> _closeHandler =
      CallbackHandler<void, void>();

  static const int _maxReconnectAttempts = 3;
  int _reconnectAttempts = 0;

  @override
  IErmesRepository getIErmesRepository() => _repository;

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

  @override
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }


  @override
  IdPeer getIdConnection() => _connectionId;



  @override
  Future<void> destroyConnection({bool close = true}) async {

    // Clear all close listeners
    _closeHandler.clear();
    await _signalingHandler.softClearConnection(_connectionId);
  }
}
