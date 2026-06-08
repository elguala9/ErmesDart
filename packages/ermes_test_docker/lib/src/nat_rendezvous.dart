// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import 'nat_test_protocol.dart';

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

/// Repeatedly calls [orc.openConnection] until the peer appears in the
/// connection set or [NatTestProtocol.rendezvousBudget] elapses.
///
/// Each attempt re-publishes a fresh signal (the handshake invokes
/// `createSignal`), keeping the NAT mapping alive across the skew between
/// the two CI jobs. Throws [NatRendezvousException] on timeout so the
/// caller can exit non-zero — the test never silently "passes" a peer it
/// could not reach.
Future<void> rendezvous(
  IOrcErmes<BookData> orc,
  String peer, {
  required String tag,
}) async {
  final sw = Stopwatch()..start();
  var attempt = 0;
  Object? lastError;

  while (sw.elapsed < NatTestProtocol.rendezvousBudget) {
    attempt++;
    try {
      print(
        '[$tag] Rendezvous attempt $attempt to $peer '
        '(${sw.elapsed.inSeconds}s elapsed)...',
      );
      await orc.openConnection(peer);
      final conns = await orc.getConnections();
      if (conns.contains(peer)) {
        print(
          '[$tag] Connected to $peer on attempt $attempt '
          '(${sw.elapsed.inSeconds}s).',
        );
        return;
      }
      lastError = 'openConnection returned but peer not in connection set';
      print('[$tag] Attempt $attempt incomplete: $lastError');
    } on Exception catch (e) {
      lastError = e;
      print('[$tag] Attempt $attempt failed: $e');
    }

    final remaining = NatTestProtocol.rendezvousBudget - sw.elapsed;
    if (remaining <= NatTestProtocol.rendezvousRetryInterval) {
      break;
    }
    await Future<void>.delayed(NatTestProtocol.rendezvousRetryInterval);
  }

  throw NatRendezvousException(peer, attempt, lastError);
}
