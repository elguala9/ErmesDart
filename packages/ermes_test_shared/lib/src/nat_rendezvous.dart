// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart' show SingletonDIAccess;

import 'message_envelope.dart';
import 'nat_diag.dart' show StunAddress, probeExternalAddress;
import 'nat_test_protocol.dart';
import 'nat_verbose.dart';

/// Raised when the rendezvous loop exhausts its wall-clock budget without
/// establishing a connection to the peer.
class NatRendezvousException implements Exception {
  /// Creates the exception with the target peer, attempt count and last error.
  NatRendezvousException(this.peer, this.attempts, this.lastError);

  /// Pubkey of the peer that could not be reached.
  final String peer;

  /// Number of rendezvous attempts made before giving up.
  final int attempts;

  /// The last error encountered, if any, before the budget elapsed.
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
  /// Creates a window with the given period and open duration, in seconds.
  const RendezvousWindow(this.periodSec, this.openSec);

  /// How often, in seconds, a dial window opens.
  final int periodSec;

  /// How long, in seconds, each window stays open for a dial.
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
  StunAddress? lastExt;

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
      lastExt = await _logPunchDiag(tag, attempt, window, lastExt);
      await orc.openConnection(peer);
      final conns = await orc.getConnections();
      if (conns.contains(peer)) {
        // openConnection only means the local connection object exists; it does
        // NOT prove the hole punch crossed. Confirm a real round trip before
        // declaring success, otherwise both peers sit "connected" while no data
        // flows (the classic two-different-windows failure).
        print(
          '[$tag] Punched to $peer on attempt $attempt '
          '(${sw.elapsed.inSeconds}s); confirming round-trip '
          '(holding mapping warm)...',
        );
        await logDialedPeerSignal(tag, peer);
        // Keep the punched mapping WARM by flooding pings, but bound each
        // attempt to [rendezvousReconfirmWindow] (capped to the remaining
        // budget) instead of consuming the whole budget in one flood. A punch
        // can land in a window the peer did not share (the two processes start
        // minutes apart), leaving each side flooding a stale port that never
        // crosses. When that happens we tear the mapping down and RE-PUNCH with
        // a fresh signal in the next synchronized window, repeating until the
        // overall budget elapses — so a single mismatched punch no longer fails
        // the whole rendezvous. The per-attempt window spans more than one full
        // period, so a correctly aligned re-punch still has time to cross.
        final remainingForConfirm = limit - sw.elapsed;
        final confirmWindow =
            remainingForConfirm < NatTestProtocol.rendezvousReconfirmWindow
            ? remainingForConfirm
            : NatTestProtocol.rendezvousReconfirmWindow;
        final live = await liveness.confirmRoundTrip(
          peer,
          window: confirmWindow,
        );
        if (live) {
          print(
            '[$tag] Round-trip confirmed with $peer '
            '(${sw.elapsed.inSeconds}s).',
          );
          await logOwnSignal(tag);
          return;
        }
        // Punched but the round trip did not cross this attempt. Tear the
        // mapping down so the next attempt re-punches cleanly, then fall
        // through to the synchronized-window pacing below and try again until
        // the budget is gone.
        lastError = 'punched but no round-trip (packets did not cross)';
        print(
          '[$tag] Attempt $attempt: $lastError — '
          're-punching in the next window.',
        );
        await orc.closeConnection(peer);
      } else {
        lastError = 'openConnection returned but peer not in connection set';
        print('[$tag] Attempt $attempt incomplete: $lastError');
      }
    } on Exception catch (e) {
      lastError = e;
      print('[$tag] Attempt $attempt failed: $e');
    }

    // Reached either when the punch produced no connection (peer not back yet)
    // or when it punched but the round trip did not cross. Either way, pace to
    // the next synchronized window so both peers re-attempt together in the
    // same slot. Stop if there is not enough budget left for another window.
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

/// Logs per-attempt NAT diagnostics: our current reflexive port (and whether
/// it churned since [previous]) plus where we sit in the dial window. Returns
/// the freshly probed address so the caller can track drift across attempts.
/// Best-effort — a failed probe leaves the previous value untouched.
Future<StunAddress?> _logPunchDiag(
  String tag,
  int attempt,
  RendezvousWindow window,
  StunAddress? previous,
) async {
  final ext = await probeExternalAddress();
  final drift = (previous != null && ext != null && previous.port != ext.port)
      ? ' (CHANGED from ${previous.ip}:${previous.port})'
      : '';
  final here = ext == null ? 'n/a' : '${ext.ip}:${ext.port}';
  final pos = _nowEpoch() % window.periodSec;
  print(
    '[$tag] DIAG attempt $attempt: ourExternal=$here$drift '
    'windowPos=${pos}s/${window.periodSec}s',
  );
  return ext ?? previous;
}

/// Current UTC time as whole seconds since the Unix epoch.
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

/// Returns the liveness handler for [orc], installing one on first use.
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
  /// Creates the liveness helper bound to the given orchestrator.
  _RendezvousLiveness(this._orc);

  /// Orchestrator used to send and receive ping/pong frames.
  final IOrcErmes<BookData> _orc;

  /// Count of pongs received per peer, keyed by peer id.
  final Map<String, int> _pongCount = {};

  /// Installs the message handler that auto-replies to pings and tallies pongs.
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

  /// Floods [DockerMsgType.rendezvousPing] at [peer] until a fresh pong returns
  /// or [window] elapses. [window] defaults to the short
  /// [NatTestProtocol.rendezvousConfirmWindow] burst; the rendezvous loop
  /// passes its full remaining budget so the punched mapping is held warm
  /// continuously (a cold re-punch never traverses a port-restricted NAT
  /// after a long outage).
  Future<bool> confirmRoundTrip(String peer, {Duration? window}) async {
    final limit = window ?? NatTestProtocol.rendezvousConfirmWindow;
    final baseline = _pongCount[peer] ?? 0;
    final sw = Stopwatch()..start();
    while (sw.elapsed < limit) {
      await _send(DockerMsgType.rendezvousPing, peer);
      if ((_pongCount[peer] ?? 0) > baseline) {
        return true;
      }
      await Future<void>.delayed(NatTestProtocol.rendezvousPingInterval);
    }
    return (_pongCount[peer] ?? 0) > baseline;
  }

  /// Best-effort send of a single control frame of [type] to [peer].
  Future<void> _send(DockerMsgType type, String peer) async {
    try {
      await _orc.send(MessageEnvelope(type: type).encode(), peer);
    } on Object {
      // Best-effort: the link may still be settling or already gone.
    }
  }
}
