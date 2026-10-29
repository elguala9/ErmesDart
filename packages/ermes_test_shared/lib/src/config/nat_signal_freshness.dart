// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart' show RegistryManager;

/// Tolerated wall-clock skew, in seconds, between two peers' hosts when
/// deciding whether a peer signal was published during this run.
const int signalClockSkewSeconds = 5;

/// How long to poll the relay, at the start of a dial window, for a peer
/// signal published during this run before dialing whatever is there.
const Duration freshSignalGrace = Duration(seconds: 4);

/// Poll period used while waiting for a fresh peer signal.
const Duration _freshSignalPoll = Duration(milliseconds: 500);

/// Whether [signal] was published no earlier than [notBeforeEpoch] (minus
/// [signalClockSkewSeconds]). A signal older than that is a leftover the relay
/// still serves from a PREVIOUS run: it is not expired (signals live 600 s in
/// production, by design) but nobody holds the mapping it advertises.
bool isSignalFromThisRun(ISignalErmes signal, int notBeforeEpoch) =>
    signal.epochTimestampStartConversation >=
    notBeforeEpoch - signalClockSkewSeconds;

/// Polls the relay (bypassing the cache) for up to [grace] until [peer]'s
/// signal satisfies [isSignalFromThisRun]. Returns true once a fresh signal is
/// cached — so `openConnection` dials it — and false when the grace elapses.
///
/// Never blocks the dial for longer than [grace]: the peer publishes its own
/// signal only when IT dials, so an unbounded wait on both sides would
/// deadlock. The bounded wait just lets a peer that dials at the same window
/// opening win the race against a previous run's leftover.
Future<bool> awaitPeerSignalFromThisRun(
  String tag,
  String peer,
  int notBeforeEpoch, {
  Duration grace = freshSignalGrace,
}) async {
  final server = RegistryManager.instance.getInstance<IErmesSignalingServer>();
  final sw = Stopwatch()..start();
  while (true) {
    try {
      final s = await server.getSignal(peer, forceRefresh: true);
      if (isSignalFromThisRun(s, notBeforeEpoch)) {
        return true;
      }
    } on Exception {
      // Peer has not published yet or transient relay failure — keep polling.
    }
    if (sw.elapsed >= grace) {
      print('[$tag] No peer signal from this run after '
          '${grace.inSeconds}s; dialing the latest one available.');
      return false;
    }
    await Future<void>.delayed(_freshSignalPoll);
  }
}
