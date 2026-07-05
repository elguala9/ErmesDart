// Verbose diagnostics for the NAT-traversal binaries. stdout is the test
// transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart' show SingletonDIAccess;

/// One-line, human-readable summary of a signal: the peer's public
/// endpoints (the STUN-discovered IP:port pairs it published to the relay)
/// plus the raw signal payload, clipped for readability.
String describeSignal(ISignalErmes s) =>
    'pubkey=${_short(s.publicKey)} '
    'ipv4=${s.ipv4}:${s.ipv4Port} '
    'ipv6=[${s.ipv6}]:${s.ipv6Port} '
    'age=${_nowEpoch() - s.epochTimestampStartConversation}s '
    'expired=${s.isExpired()} '
    'raw=${_clip(s.signal)}';

/// Current UTC time as whole seconds since the Unix epoch, used to report how
/// stale a signal is (a large `age` on a re-punch means the peer is dialing a
/// mapping we no longer hold — a signalling race, not a NAT-type problem).
int _nowEpoch() => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

/// Logs the signal THIS peer currently publishes to the relay — i.e. the
/// endpoints the other side will dial. Best-effort: before the first
/// handshake the owner signal may not exist yet.
Future<void> logOwnSignal(String tag) async {
  try {
    final repo =
        SingletonDIAccess.get<IErmesSignalingRepository<ISignalErmes>>();
    final own = await repo.getSignalOwner();
    print('[$tag] OWN SIGNAL (published to relay): ${describeSignal(own)}');
  } on Object catch (e) {
    print('[$tag] OWN SIGNAL not available yet: $e');
  }
}

/// Registers a push listener so every signal the relay delivers is logged
/// as it arrives. This is purely passive — it never fetches from the relay
/// itself, so it cannot interfere with the rendezvous (an explicit forced
/// `getSignal` here poisons the signal cache and breaks `openConnection`).
void installSignalListener(String tag) {
  SingletonDIAccess.get<IErmesSignalingServer>().onSignal(
    (sig) => print('[$tag] <~ SIGNAL pushed by relay: ${describeSignal(sig)}'),
  );
}

/// Shortens a 64-hex pubkey to its first 12 chars for readable logs.
String shortId(String id) => id.length <= 12 ? id : '${id.substring(0, 12)}…';

/// Shortens a pubkey for logs via [shortId].
String _short(String pubkey) => shortId(pubkey);

/// Clips a string to at most 80 chars, appending an ellipsis when truncated.
String _clip(String s) => s.length <= 80 ? s : '${s.substring(0, 80)}…';
