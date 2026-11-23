import 'package:iermes/iermes.dart';

/// Detects peers unreachable because of a symmetric NAT or blocked UDP (RFC
/// ermes-protocol section 5): after [maxFailedAttempts] consecutive dials
/// that never connected, the peer is flagged permanently and further
/// attempts fail fast with [ErmesSymmetricNatException].
///
/// A [maxFailedAttempts] of 0 disables detection. Any successful connection
/// resets that peer's counter, so slow rendezvous alone is not flagged.
class OrcSymmetricNatDetector {
  OrcSymmetricNatDetector({this.maxFailedAttempts = 0});

  /// Consecutive failed dials before a peer is flagged; 0 disables.
  final int maxFailedAttempts;

  final Map<IdPeer, int> _failures = {};
  final Set<IdPeer> _flagged = {};

  bool get enabled => maxFailedAttempts > 0;

  /// Throws when [peer] was already flagged, so callers skip the dial.
  void assertAllowed(IdPeer peer) {
    if (_flagged.contains(peer)) {
      throw _exceptionFor(peer);
    }
  }

  /// Records a dial outcome for [peer]; throws when it trips the threshold.
  void record(IdPeer peer, {required bool connected}) {
    if (!enabled) {
      return;
    }
    if (connected) {
      _failures.remove(peer);
      return;
    }
    final count = (_failures[peer] ?? 0) + 1;
    _failures[peer] = count;
    if (count >= maxFailedAttempts) {
      _flagged.add(peer);
      throw _exceptionFor(peer);
    }
  }

  /// Clears the flag and counter for [peer] (explicit application retry).
  void reset(IdPeer peer) {
    _failures.remove(peer);
    _flagged.remove(peer);
  }

  ErmesSymmetricNatException _exceptionFor(IdPeer peer) =>
      ErmesSymmetricNatException(
        'Peer $peer unreachable after $maxFailedAttempts failed dials: '
        'symmetric NAT or blocked UDP (unsupported, not retried)',
      );
}
