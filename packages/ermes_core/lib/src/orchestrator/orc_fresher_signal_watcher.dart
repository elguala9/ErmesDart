import 'package:iermes/iermes.dart';

import '../peer_connection/ermes_peer.dart';
import 'orc_peer_signal_waiter.dart';

/// Watches a freshly dialed peer for either a live connection or a peer
/// signal fresher than the one in use, on behalf of `OrcConnectionOpener`.
class OrcFresherSignalWatcher {
  /// Creates a watcher polling [signalingServer] and filtering signals
  /// through [signalWaiter].
  OrcFresherSignalWatcher(this.signalingServer, this.signalWaiter);

  /// Relay the peer signal is polled from.
  final IErmesSignalingServer signalingServer;

  /// Decides whether a polled peer signal is usable.
  final OrcPeerSignalWaiter signalWaiter;

  static const Duration _confirmPollInterval = Duration(milliseconds: 500);

  // How long a fresh dial is watched for a live connection or a superseding
  // (fresher) peer signal. Deliberately short and independent of
  // connectionTimeoutMs: this watch runs its FULL budget whenever the dialed
  // peer does not flip `isConnected()` (e.g. right after a reconnect), so a
  // long value would stall every such open. Re-attempts against a stale port
  // are the OUTER rendezvous loop's job (it re-punches each window); the real
  // stale-signal defence is [OrcPeerSignalWaiter.isUsable] up front.
  static const int _redialConfirmMs = 5000;

  /// Watch budget for a dial given the opener's [connectionTimeoutMs].
  static Duration budgetFor(int connectionTimeoutMs) => Duration(
        milliseconds: connectionTimeoutMs < _redialConfirmMs
            ? connectionTimeoutMs
            : _redialConfirmMs,
      );

  /// Returns `null` once [ermesPeer] connects or the budget runs out (caller
  /// keeps the optimistic peer), or a peer signal newer than [current] when
  /// one appears so the caller can re-dial toward the live mapping.
  Future<ISignalErmes?> awaitConnectionOrFresher(
    IdPeer peer,
    ErmesPeer ermesPeer,
    ISignalErmes current,
    Stopwatch sw,
    Duration budget,
    ISignalErmes ourSignal,
  ) async {
    while (sw.elapsed < budget) {
      if (ermesPeer.isConnected()) {
        return null;
      }
      try {
        final s = await signalingServer.getSignal(peer, forceRefresh: true);
        if (signalWaiter.isUsable(s, ourSignal) &&
            s.epochTimestampStartConversation >
                current.epochTimestampStartConversation) {
          return s;
        }
      } on Exception {
        // transient relay read failure - keep polling
      }
      await Future<void>.delayed(_confirmPollInterval);
    }
    return null;
  }
}
