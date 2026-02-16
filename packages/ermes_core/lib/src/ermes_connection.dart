import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';

/// Implementation of IErmesConnection that manages peer connections through
/// signaling and handles repository management and reconnection
@includeInBarrelFile
class ErmesConnection implements IErmesConnection {
  ErmesConnection(
    this._signalingHandler,
    this._repository,
    this._connectionId,
  );
  final IErmesSignalingHandler<dynamic> _signalingHandler;
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
      throw Exception(
        'Maximum reconnection attempts ($_maxReconnectAttempts) exceeded',
      );
    }

    _reconnectAttempts++;

    try {
      // Step 1: Save current state before attempting reconnection


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
  IdPeer getIdConnection() => _connectionId;



  @override
  Future<void> destroyConnection({bool close = true}) async {

    // Clear all close listeners
    _closeHandler.clear();
    await _signalingHandler.softClearConnection(_connectionId);
  }
}
