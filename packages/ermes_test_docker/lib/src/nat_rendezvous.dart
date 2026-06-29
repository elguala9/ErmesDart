// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart' show SingletonDIAccess;

import 'message_envelope.dart';
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
  Duration? budget,
}) async {
  final limit = budget ?? NatTestProtocol.rendezvousBudget;
  final liveness = await _ensureLiveness(orc);
  final sw = Stopwatch()..start();
  var attempt = 0;
  Object? lastError;

  while (sw.elapsed < limit) {
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
        // openConnection only means the local connection object exists; it does
        // NOT prove the hole punch crossed. Confirm a real round trip before
        // declaring success, otherwise both peers sit "connected" while no data
        // flows (the classic two-different-windows failure).
        print(
          '[$tag] Punched to $peer on attempt $attempt '
          '(${sw.elapsed.inSeconds}s); confirming round-trip...',
        );
        final live = await liveness.confirmRoundTrip(peer);
        if (live) {
          print(
            '[$tag] Round-trip confirmed with $peer '
            '(${sw.elapsed.inSeconds}s).',
          );
          await logOwnSignal(tag);
          return;
        }
        lastError = 'punched but no round-trip (packets did not cross)';
        print('[$tag] Attempt $attempt: $lastError — re-dialing.');
        // openConnection treats the local socket as "connected" and would skip
        // the re-punch; tear it down so the next attempt punches afresh.
        await orc.closeConnection(peer);
      } else {
        lastError = 'openConnection returned but peer not in connection set';
        print('[$tag] Attempt $attempt incomplete: $lastError');
      }
    } on Exception catch (e) {
      lastError = e;
      print('[$tag] Attempt $attempt failed: $e');
    }

    // One dial per window: sleep to the start of the next period so both
    // peers re-attempt together in the next synchronized slot.
    final toNext = secondsToNextPeriod(window);
    final remaining = limit - sw.elapsed;
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

/// One [_RendezvousLiveness] per orchestrator, installed lazily on the first
/// [rendezvous] call. Keyed by identity so re-rendezvous (after a break) reuses
/// the same handler instead of stacking a new one each time.
final Map<IOrcErmes<BookData>, _RendezvousLiveness> _livenessByOrc = {};

Future<_RendezvousLiveness> _ensureLiveness(IOrcErmes<BookData> orc) async {
  final existing = _livenessByOrc[orc];
  if (existing != null) {
    return existing;
  }
  final liveness = _RendezvousLiveness(orc);
  _livenessByOrc[orc] = liveness;
  await liveness.install();
  return liveness;
}

/// Confirms that a punched channel actually carries data both ways.
///
/// Installs a permanent message handler (callbacks accumulate in the core, so
/// it coexists with each scenario's own handler) that auto-replies a
/// [DockerMsgType.rendezvousPong] to every [DockerMsgType.rendezvousPing] it
/// sees. [confirmRoundTrip] floods pings at the peer and only returns true once
/// a fresh pong comes back — proof the hole punch crossed in both directions.
class _RendezvousLiveness {
  _RendezvousLiveness(this._orc);

  final IOrcErmes<BookData> _orc;
  final Map<String, int> _pongCount = {};

  Future<void> install() async {
    await _orc.onMessage((data, from) {
      final DockerMsgType type;
      try {
        type = MessageEnvelope.decode(data).type;
      } on Object {
        return; // not a frame we care about
      }
      if (type == DockerMsgType.rendezvousPing) {
        unawaited(_send(DockerMsgType.rendezvousPong, from));
      } else if (type == DockerMsgType.rendezvousPong) {
        _pongCount[from] = (_pongCount[from] ?? 0) + 1;
      }
    });
  }

  Future<bool> confirmRoundTrip(String peer) async {
    final baseline = _pongCount[peer] ?? 0;
    final sw = Stopwatch()..start();
    while (sw.elapsed < NatTestProtocol.rendezvousConfirmWindow) {
      await _send(DockerMsgType.rendezvousPing, peer);
      if ((_pongCount[peer] ?? 0) > baseline) {
        return true;
      }
      await Future<void>.delayed(NatTestProtocol.rendezvousPingInterval);
    }
    return (_pongCount[peer] ?? 0) > baseline;
  }

  Future<void> _send(DockerMsgType type, String peer) async {
    try {
      await _orc.send(MessageEnvelope(type: type).encode(), peer);
    } on Object {
      // Best-effort: the link may still be settling or already gone.
    }
  }
}
