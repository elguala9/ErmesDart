// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart' show SingletonDIAccess;

import 'nat_test_protocol.dart';
import 'nat_verbose.dart';

/// Raised when the rendezvous loop exhausts its wall-clock budget without
/// establishing a connection to the peer.
class NatRendezvousException implements Exception {
  NatRendezvousException(this.peer, this.attempts, this.lastError);

  final String peer;
  final int attempts;
  final Object? lastError;

  @override
  String toString() =>
      'NatRendezvousException: failed to connect to $peer '
      'after $attempts attempt(s); last error: $lastError';
}

/// The synchronized dial window carried in a signal's interval fields.
///
/// [periodSec] is how often a window opens; [openSec] is how long it stays
/// open. Both values come from the signal each peer publishes, so the two
/// sides agree on the same windows.
class RendezvousWindow {
  const RendezvousWindow(this.periodSec, this.openSec);

  final int periodSec;
  final int openSec;
}

/// Repeatedly calls [orc.openConnection] until the peer appears in the
/// connection set or [NatTestProtocol.rendezvousBudget] elapses.
///
/// Attempts are paced by the interval window the signal carries
/// (`secondsIntervalOpening` / `secondsIntervalWindow`): both peers align
/// their dials to the same absolute wall-clock periods
/// (`epoch % periodSec < openSec`), so even when the two processes start
/// minutes apart (peer on Actions vs. peer running locally) their dials
/// land in the same slot and their hole-punch packets cross. This also
/// exercises the signal's interval fields end to end — the values published
/// in the signal directly drive the rendezvous timing.
///
/// Each attempt re-publishes a fresh signal (the handshake invokes
/// `createSignal`), keeping the NAT mapping alive across the skew between
/// the two peers. Throws [NatRendezvousException] on timeout so the caller
/// can exit non-zero — the test never silently "passes" a peer it could
/// not reach.
Future<void> rendezvous(
  IOrcErmes<BookData> orc,
  String peer, {
  required String tag,
}) async {
  final sw = Stopwatch()..start();
  var attempt = 0;
  Object? lastError;

  while (sw.elapsed < NatTestProtocol.rendezvousBudget) {
    final window = await resolveRendezvousWindow();
    final untilOpen = secondsUntilWindowOpen(window);
    if (untilOpen > 0) {
      print(
        '[$tag] Outside rendezvous window (open ${window.openSec}s every '
        '${window.periodSec}s); next window in ${untilOpen}s '
        '(${sw.elapsed.inSeconds}s elapsed)...',
      );
      await Future<void>.delayed(Duration(seconds: untilOpen));
      continue;
    }

    attempt++;
    try {
      print(
        '[$tag] Rendezvous attempt $attempt to $peer in window '
        '(${sw.elapsed.inSeconds}s elapsed)...',
      );
      await orc.openConnection(peer);
      final conns = await orc.getConnections();
      if (conns.contains(peer)) {
        print(
          '[$tag] Connected to $peer on attempt $attempt '
          '(${sw.elapsed.inSeconds}s).',
        );
        await logOwnSignal(tag);
        return;
      }
      lastError = 'openConnection returned but peer not in connection set';
      print('[$tag] Attempt $attempt incomplete: $lastError');
    } on Exception catch (e) {
      lastError = e;
      print('[$tag] Attempt $attempt failed: $e');
    }

    // One dial per window: sleep to the start of the next period so both
    // peers re-attempt together in the next synchronized slot.
    final toNext = secondsToNextPeriod(window);
    final remaining = NatTestProtocol.rendezvousBudget - sw.elapsed;
    if (remaining.inSeconds <= toNext) {
      break;
    }
    print('[$tag] Window done; next synchronized attempt in ${toNext}s.');
    await Future<void>.delayed(Duration(seconds: toNext));
  }

  throw NatRendezvousException(peer, attempt, lastError);
}

int _nowEpoch() => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

/// Reads the interval window THIS peer publishes in its own signal, so the
/// rendezvous is governed by the exact values carried on the wire. Falls
/// back to the protocol defaults before the first signal is published (the
/// defaults match `createSignal`, so behaviour is identical either way).
Future<RendezvousWindow> resolveRendezvousWindow() async {
  try {
    final repo =
        SingletonDIAccess.get<IErmesSignalingRepository<ISignalErmes>>();
    final own = await repo.getSignalOwner();
    if (own.secondsIntervalOpening > 0 && own.secondsIntervalWindow > 0) {
      return RendezvousWindow(
        own.secondsIntervalOpening,
        own.secondsIntervalWindow,
      );
    }
  } on Object {
    // Own signal not published yet — use the defaults both sides agree on.
  }
  return const RendezvousWindow(
    NatTestProtocol.windowPeriodSeconds,
    NatTestProtocol.windowOpenSeconds,
  );
}

/// Seconds until the next window opens, or 0 when the current moment is
/// already inside an open window.
int secondsUntilWindowOpen(RendezvousWindow w) {
  final pos = _nowEpoch() % w.periodSec;
  return pos < w.openSec ? 0 : w.periodSec - pos;
}

/// Seconds from now to the start of the next period (always >= 1), used to
/// pace exactly one dial per window.
int secondsToNextPeriod(RendezvousWindow w) {
  final to = w.periodSec - (_nowEpoch() % w.periodSec);
  return to <= 0 ? w.periodSec : to;
}
