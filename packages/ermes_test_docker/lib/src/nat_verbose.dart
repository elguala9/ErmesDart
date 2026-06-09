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
    'expired=${s.isExpired()} '
    'raw=${_clip(s.signal)}';

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

/// Fetches the peer's signal straight from the relay (forcing a refresh,
/// bypassing any cache) and logs it. This is the exact moment a peer
/// "retrieves" the other side's signal from Nostr.
Future<void> logPeerSignal(String tag, String peer) async {
  try {
    final server = SingletonDIAccess.get<IErmesSignalingServer>();
    final sig = await server.getSignal(peer, forceRefresh: true);
    print('[$tag] PEER SIGNAL fetched from relay: ${describeSignal(sig)}');
  } on Object catch (e) {
    print('[$tag] PEER SIGNAL not on relay yet ($peer): $e');
  }
}

/// Registers a push listener so every signal the relay delivers is logged
/// as it arrives, independently of the explicit fetches above.
void installSignalListener(String tag) {
  SingletonDIAccess.get<IErmesSignalingServer>().onSignal(
    (sig) => print('[$tag] <~ SIGNAL pushed by relay: ${describeSignal(sig)}'),
  );
}

/// Shortens a 64-hex pubkey to its first 12 chars for readable logs.
String shortId(String id) => id.length <= 12 ? id : '${id.substring(0, 12)}…';

String _short(String pubkey) => shortId(pubkey);

String _clip(String s) => s.length <= 80 ? s : '${s.substring(0, 80)}…';
