import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';

/// 2️⃣ ErmesSignalingReconnector - Gestore riconnessione signaling
/// Tradotto da: ErmesSignalingReconnector.ts
///
/// Responsabilità:
/// - Riconnessione automatica con max 3 tentativi
/// - Gestione errori e cleanup
/// - Retry logic

class ErmesSignalingReconnector {
  ErmesSignalingReconnector(this._signalingHandler, this._signalingServer);
  final IErmesSignalingHandler<IShspSocket> _signalingHandler;
  final IErmesSignalingServer _signalingServer;
  bool _isReconnecting = false;
  static const int _maxReconnectAttempts = 3;
  int _reconnectAttempts = 0;

  /// Attempts to reconnect a peer by its connectionId
  Future<void> reconnect(String connectionId) async {
    if (_isReconnecting) {
      throw Exception('Reconnection already in progress');
    }
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      throw Exception('Maximum reconnection attempts exceeded');
    }

    _isReconnecting = true;
    _reconnectAttempts++;

    try {
      await _signalingHandler.clearConnection(connectionId);
      await _signalingServer.getSignal(connectionId);
    } finally {
      _isReconnecting = false;
    }
  }

  void resetAttempts() => _reconnectAttempts = 0;
  int get reconnectAttempts => _reconnectAttempts;
  bool get isReconnecting => _isReconnecting;
}
