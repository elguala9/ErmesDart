import 'dart:async';

import 'package:iermes/iermes.dart';

import '../support/exceptions.dart';

/// Polls the relay for a usable peer signal while keeping our own signal
/// fresh, so two peers waiting on each other always see a live counterpart.
///
/// Previously the wait only read: a peer blocked here stopped advertising,
/// its signal aged past the stale threshold, and the counterpart waited for
/// a republish that only came on the next dial — each side ended up dialing
/// one window after the other and their punches never overlapped.
class OrcPeerSignalWaiter {
  /// Creates a waiter reading from [_server] and republishing our signal
  /// through [_publish]; it gives up after [maxAttempts] polls spaced by
  /// [pollInterval] so the outer rendezvous loop can re-pace.
  OrcPeerSignalWaiter(
    this._server,
    this._publish, {
    this.maxAttempts = 60,
    this.pollInterval = const Duration(seconds: 1),
  });

  final IErmesSignalingServer _server;
  final Future<ISignalErmes> Function(IdPeer peer) _publish;

  /// Polls before giving up.
  final int maxAttempts;

  /// Delay between two polls.
  final Duration pollInterval;

  /// Declared republish periods a peer signal may be old before it is stale.
  static const int _maxSignalAgeFactor = 2;

  /// Waits for a usable signal of [peer], republishing [ourSignal] every
  /// half of its declared period. Throws [CoreException] after
  /// [maxAttempts] polls.
  Future<ISignalErmes> wait(IdPeer peer, ISignalErmes ourSignal) async {
    final sincePublish = Stopwatch()..start();
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        // Force a relay round-trip: a cached read can pin a stale signal.
        final s = await _server.getSignal(peer, forceRefresh: true);
        if (isUsable(s, ourSignal)) {
          return s;
        }
      } on Exception {
        // peer hasn't published yet — keep polling
      }
      await _republishIfDue(peer, ourSignal, sincePublish);
      await Future<void>.delayed(pollInterval);
    }
    throw CoreException(
      'Timeout waiting for peer signal after $maxAttempts attempts',
    );
  }

  /// True when [s] is unexpired, not our own reflected signal and not stale.
  bool isUsable(ISignalErmes s, ISignalErmes ourSignal) =>
      !s.isExpired() && !_isSelfSignal(s, ourSignal) && !_isStale(s);

  Future<void> _republishIfDue(
    IdPeer peer,
    ISignalErmes ourSignal,
    Stopwatch sincePublish,
  ) async {
    final period = ourSignal.secondsIntervalOpening;
    if (period <= 0 || sincePublish.elapsed.inSeconds * 2 < period) {
      return;
    }
    sincePublish.reset();
    try {
      await _publish(peer);
    } on Exception {
      // Best-effort: retried at the next due tick.
    }
  }

  /// True when [s] is older than [_maxSignalAgeFactor] declared periods: a
  /// leftover of a process that stopped advertising, even if not expired.
  /// Signals declaring no period keep the expiry-only behaviour.
  bool _isStale(ISignalErmes s) {
    if (s.secondsIntervalOpening <= 0) {
      return false;
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final age = now - s.epochTimestampStartConversation;
    return age > _maxSignalAgeFactor * s.secondsIntervalOpening;
  }

  /// True when [candidate] advertises the endpoint we published in [ours]:
  /// only our own signal reflected by the relay can match IP and port.
  bool _isSelfSignal(ISignalErmes candidate, ISignalErmes ours) {
    final sameV4 = candidate.ipv4.isNotEmpty &&
        candidate.ipv4 == ours.ipv4 &&
        candidate.ipv4Port == ours.ipv4Port;
    final sameV6 = candidate.ipv6.isNotEmpty &&
        candidate.ipv6 == ours.ipv6 &&
        candidate.ipv6Port == ours.ipv6Port;
    return sameV4 || sameV6;
  }
}
