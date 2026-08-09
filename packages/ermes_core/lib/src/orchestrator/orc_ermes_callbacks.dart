import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

/// Message-callback registration and peer reconnection logic for [OrcErmes].
///
/// Owns the message/disconnect callback lists and the bounded, exponentially
/// backed-off reconnect loop. Relies on the host's `openConnection` (from
/// `IOrcErmes`) to re-establish a dropped peer.
mixin OrcErmesCallbacks implements IOrcErmes<BookData> {
  static const int maxReconnectAttempts = 3;

  final List<CallbackOnDataArrivedFrom> _messageCallbacks = [];
  final List<void Function(IdPeer)> _disconnectCallbacks = [];

  /// Fans an inbound message out to every registered message callback.
  void dispatchMessage(TypeOfData data, IdPeer from) {
    for (final cb in _messageCallbacks) {
      cb(data, from);
    }
  }

  @override
  Future<void> onMessage(CallbackOnDataArrivedFrom callbackOnData) async =>
      _messageCallbacks.add(callbackOnData);

  @override
  Future<void> onDisconnect(void Function(IdPeer peer) callback) async =>
      _disconnectCallbacks.add(callback);

  /// Clears registered message callbacks (used while destroying).
  void clearMessageCallbacks() => _messageCallbacks.clear();

  /// Attempts to reconnect [peer], backing off exponentially. After
  /// [maxReconnectAttempts] failures it notifies the disconnect callbacks.
  Future<void> handlePeerDisconnect(IdPeer peer, [int attempt = 1]) async {
    if (attempt > maxReconnectAttempts) {
      for (final cb in _disconnectCallbacks) {
        cb(peer);
      }
      return;
    }
    await Future<void>.delayed(Duration(seconds: 1 << (attempt - 1)));
    try {
      await openConnection(peer);
    } on Exception catch (_) {
      await handlePeerDisconnect(peer, attempt + 1);
    }
  }
}
