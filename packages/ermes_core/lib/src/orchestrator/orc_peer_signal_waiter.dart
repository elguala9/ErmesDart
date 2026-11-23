import 'dart:async';

import 'package:iermes/iermes.dart';

import '../support/exceptions.dart';
import 'ermes_signal_last_seen_store.dart';

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
  /// [pollInterval] so the outer rendezvous loop can re-pace. [lastSeen]
  /// tracks the newest accepted signal per counterpart (RFC section 6.1); a
  /// private store is used when none is shared.
  OrcPeerSignalWaiter(
    this._server,
    this._publish, {
    this.maxAttempts = 60,
    this.pollInterval = const Duration(seconds: 1),
    IErmesSignalLastSeenStore? lastSeen,
  }) : lastSeen = lastSeen ?? ErmesSignalLastSeenStore();

  final IErmesSignalingServer _server;
  final Future<ISignalErmes> Function(IdPeer peer) _publish;

  /// Polls before giving up.
  final int maxAttempts;

  /// Delay between two polls.
  final Duration pollInterval;

  /// Newest accepted signal start per counterpart.
  final IErmesSignalLastSeenStore lastSeen;

  /// Seconds a signal start may lie in the future before it is rejected as
  /// not yet valid: absorbs clock skew between peers.
  static const int clockSkewToleranceSeconds = 30;

  /// Declared republish periods a peer signal may be old before it is stale.
  static const int _maxSignalAgeFactor = 2;

  /// Waits for a usable signal of [peer], republishing [ourSignal] every
  /// half of its declared period. Throws [CoreException] after
  /// [maxAttempts] polls.
  Future<ISignalErmes> wait(IdPeer peer, ISignalErmes ourSignal) async {
    final sincePublish = Stopwatch()..start();
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        // Relay first, cached signal when the relay answers empty: a relay
        // read alone can keep failing while a valid signal sits in the cache,
        // stalling the dial. Stale or expired signals are still rejected by
        // [isUsable].
        final s = await _server.getSignal(peer);
        if (isUsable(s, ourSignal, peer: peer)) {
          return accept(peer, s);
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

  /// True when [s] is unexpired, already valid, not our own reflected signal
  /// and not stale; with [peer], also not older than the last signal
  /// accepted for that counterpart.
  bool isUsable(ISignalErmes s, ISignalErmes ourSignal, {IdPeer? peer}) =>
      !s.isExpired() &&
      !_isSelfSignal(s, ourSignal) &&
      !_isStale(s) &&
      !_isNotYetValid(s) &&
      (peer == null || !lastSeen.isRegression(peer, s));

  /// Records [s] as the newest accepted signal of [peer] and returns it.
  ISignalErmes accept(IdPeer peer, ISignalErmes s) {
    lastSeen.record(peer, s);
    return s;
  }

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
    final age = _now() - s.epochTimestampStartConversation;
    return age > _maxSignalAgeFactor * s.secondsIntervalOpening;
  }

  /// True when [s] starts more than [clockSkewToleranceSeconds] from now.
  bool _isNotYetValid(ISignalErmes s) =>
      s.epochTimestampStartConversation > _now() + clockSkewToleranceSeconds;

  static int _now() => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

  /// True when [candidate] was published by us. RFC section 6.1: compare
  /// IdSignaling only; (address, port) equality MUST NOT be used, since peers
  /// behind one NAT can share an endpoint and our own mapping can change.
  bool _isSelfSignal(ISignalErmes candidate, ISignalErmes ours) =>
      candidate.idSignaling == ours.idSignaling;
}
