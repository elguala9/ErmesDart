import 'dart:async';

import 'package:iermes/iermes.dart';

import '../peer_connection/ermes_peer.dart';
import 'orc_ermes_connection_opener.dart';
import 'orc_fresher_signal_watcher.dart';
import 'orc_opener_dialer.dart';

/// Out-of-band dialing (RFC ermes-protocol section 6.2).
extension OrcStaticSignalOpener on OrcConnectionOpener {
  /// Dials every common family from [signal] without reading or writing the
  /// relay, waits up to the watch budget for a live Connection and feeds the
  /// symmetric-NAT detector.
  Future<Map<ErmesConnectionContext, ErmesPeer>> openStatic(
    IdPeer peer,
    ISignalErmes signal,
    void Function(TypeOfData data, IdPeer from) onData,
    Future<void> Function(IdPeer peer) onPeerDisconnect,
    Set<ErmesConnectionContext> skip,
  ) async {
    final dialed = await dialAll(peer, signal, onData, skip);
    final sw = Stopwatch()..start();
    final budget = OrcFresherSignalWatcher.budgetFor(connectionTimeoutMs);
    while (!dialed.values.any((c) => c.isConnected()) && sw.elapsed < budget) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return settle(peer, dialed, onPeerDisconnect);
  }

  /// Feeds the dial outcome to [natDetector] (which throws on a permanent
  /// failure) and wires the disconnect listeners of [dialed].
  Future<Map<ErmesConnectionContext, ErmesPeer>> settle(
    IdPeer peer,
    Map<ErmesConnectionContext, ErmesPeer> dialed,
    Future<void> Function(IdPeer peer) onPeerDisconnect,
  ) async {
    try {
      natDetector.record(peer,
          connected: dialed.values.any((c) => c.isConnected()));
    } on ErmesSymmetricNatException {
      for (final connection in dialed.values) {
        await connection.dispose();
      }
      rethrow;
    }
    for (final connection in dialed.values) {
      connection.addOnDisconnectListener(
        () => unawaited(onPeerDisconnect(peer)),
      );
    }
    return dialed;
  }
}
