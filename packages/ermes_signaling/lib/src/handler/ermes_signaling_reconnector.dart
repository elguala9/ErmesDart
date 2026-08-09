import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../support/exceptions.dart';

/// Signal-channel reconnection manager.
///
/// Responsibilities:
/// - Automatic reconnection with a bounded number of attempts.
/// - Exponential backoff delay between attempts (no immediate hammering).
/// - Error handling and cleanup.
class ErmesSignalingReconnector {
  /// Creates a reconnector with configurable backoff bounds and an
  /// injectable delay function for testing.
  ErmesSignalingReconnector(
    this._signalingHandler,
    this._signalingServer, {
    Duration baseReconnectDelay = const Duration(milliseconds: 500),
    Duration maxReconnectDelay = const Duration(seconds: 30),
    Future<void> Function(Duration)? delay,
  }) : _baseReconnectDelay = baseReconnectDelay,
       _maxReconnectDelay = maxReconnectDelay,
       _delay = delay ?? Future<void>.delayed;

  /// Handler whose connection is cleared before each reconnection attempt.
  final IErmesSignalingHandler<IShspSocket> _signalingHandler;

  /// Server queried to re-fetch the peer signal during reconnection.
  final IErmesSignalingServer _signalingServer;

  /// Base delay used as the starting point for exponential backoff.
  final Duration _baseReconnectDelay;

  /// Upper bound the backoff delay is capped at.
  final Duration _maxReconnectDelay;

  /// Delay function used to wait between attempts (overridable in tests).
  final Future<void> Function(Duration) _delay;

  /// Whether a reconnection attempt is currently running.
  bool _isReconnecting = false;

  /// Maximum number of reconnection attempts before giving up.
  static const int _maxReconnectAttempts = 3;

  /// Count of consecutive reconnection attempts made so far.
  int _reconnectAttempts = 0;

  /// Attempts to reconnect a peer by its connectionId.
  ///
  /// Each attempt waits `baseReconnectDelay * 2^(attempt-1)` (capped at
  /// `maxReconnectDelay`) before reaching out, so repeated failures back off
  /// exponentially instead of retrying immediately.
  Future<void> reconnect(String connectionId) async {
    if (_isReconnecting) {
      throw SignalingException('Reconnection already in progress');
    }
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      throw SignalingException('Maximum reconnection attempts exceeded');
    }

    _isReconnecting = true;
    final previousAttempts = _reconnectAttempts;
    _reconnectAttempts++;

    try {
      await _delay(_backoffFor(previousAttempts));
      await _signalingHandler.clearConnection(connectionId);
      await _signalingServer.getSignal(connectionId);
      _reconnectAttempts = 0;
    } finally {
      _isReconnecting = false;
    }
  }

  /// Computes the backoff delay for the given count of prior attempts.
  /// First attempt (0 prior) is immediate; later attempts grow exponentially.
  Duration _backoffFor(int priorAttempts) {
    if (priorAttempts <= 0) {
      return Duration.zero;
    }
    final factor = 1 << (priorAttempts - 1);
    final millis = _baseReconnectDelay.inMilliseconds * factor;
    return millis >= _maxReconnectDelay.inMilliseconds
        ? _maxReconnectDelay
        : Duration(milliseconds: millis);
  }

  /// Resets the reconnection attempt counter back to zero.
  void resetAttempts() => _reconnectAttempts = 0;

  /// Number of reconnection attempts made since the last successful reset.
  int get reconnectAttempts => _reconnectAttempts;

  /// Whether a reconnection attempt is currently in progress.
  bool get isReconnecting => _isReconnecting;
}
