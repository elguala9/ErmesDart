// DEBUG-ONLY: temporary diagnostics for task
// `nat-hole-punch-flaky-punched-but-no-round-trip`. Remove this file and its
// `watchDial` calls in nat_rendezvous.dart once the openConnection stall is
// understood.
//
// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart' show RegistryManager;

import 'nat_verbose.dart' show describeSignal;

/// How often [watchDial] reports while a dial phase is still running.
const Duration dialWatchInterval = Duration(seconds: 10);

/// Awaits [phase] and logs how long it took. While it runs, every
/// [dialWatchInterval] it prints the peer signal currently cached for [peer].
///
/// Pinpoints the "alternating windows" failure: one peer stays inside
/// `openConnection` for a whole slot (about 2 minutes) before its first punch
/// packet leaves, so the two peers punch one slot apart and never overlap.
/// The periodic line shows whether the stuck peer already held a fresh peer
/// signal (the delay is after the signal wait) or not (the relay read lags).
Future<T> watchDial<T>(
  String tag,
  String peer,
  String phaseName,
  Future<T> phase,
) async {
  final sw = Stopwatch()..start();
  final ticker = Timer.periodic(dialWatchInterval, (_) {
    unawaited(_logCachedPeerSignal(tag, peer, phaseName, sw.elapsed));
  });
  try {
    return await phase;
  } finally {
    ticker.cancel();
    print('[$tag] [DIAL-WATCH] $phaseName took ${sw.elapsed.inSeconds}s');
  }
}

/// Prints the peer signal via `getSignal` without `forceRefresh`. A valid
/// cached entry is served locally; a missing or expired one triggers a relay
/// read (`retrieveLast`, about 6 s). So when no signal is cached, this adds
/// at most one relay read every [dialWatchInterval]. Best-effort: never
/// throws.
Future<void> _logCachedPeerSignal(
  String tag,
  String peer,
  String phaseName,
  Duration elapsed,
) async {
  final prefix =
      '[$tag] [DIAL-WATCH] $phaseName still running '
      '(${elapsed.inSeconds}s)';
  final server = RegistryManager.instance.getInstance<IErmesSignalingServer>();
  try {
    final s = await server.getSignal(peer);
    print('$prefix; cached peer signal: ${describeSignal(s)}');
  } on Object catch (e) {
    print('$prefix; no cached peer signal: $e');
  }
  await _logRelayPeerSignal(server, peer, prefix);
}

/// Reads [peer]'s signal exactly as `OrcPeerSignalWaiter.wait` does
/// (`forceRefresh: true`) and prints the verdict of each `isUsable` check
/// (expired, stale = older than 2 declared periods, idSignaling), or the
/// exception the waiter would swallow before polling again.
Future<void> _logRelayPeerSignal(
  IErmesSignalingServer server,
  String peer,
  String prefix,
) async {
  final sw = Stopwatch()..start();
  try {
    final s = await server.getSignal(peer, forceRefresh: true);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final age = now - s.epochTimestampStartConversation;
    final period = s.secondsIntervalOpening;
    final stale = period > 0 && age > 2 * period;
    print(
      '$prefix; RELAY read (${sw.elapsed.inMilliseconds}ms): '
      'expired=${s.isExpired()} stale=$stale (age=${age}s '
      'period=${period}s) idSignaling=${s.idSignaling} '
      'ipv4=${s.ipv4}:${s.ipv4Port}',
    );
  } on Object catch (e) {
    print(
      '$prefix; RELAY read FAILED (${sw.elapsed.inMilliseconds}ms) '
      '${e.runtimeType}: $e',
    );
  }
}
