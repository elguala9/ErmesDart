import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import '../peer_connection/ermes_peer.dart';
import '../peer_connection/ermes_peer_factory.dart';
import '../support/exceptions.dart';
import 'orc_ermes_connection_opener.dart';
import 'orc_opener_peer_config.dart';
import 'orc_peer_info_from_signal.dart';

/// Dialing half of [OrcConnectionOpener]: one independent Connection per
/// address family common to our sockets and the peer's signal.
extension OrcOpenerDialer on OrcConnectionOpener {
  /// Dials every family common to our sockets and [peerSignal] (minus
  /// [skip]). Peers are created synchronously, one family at a time, because
  /// the repository reads the book's peer info at construction.
  Future<Map<ErmesConnectionContext, ErmesPeer>> dialAll(
    IdPeer peer,
    ISignalErmes peerSignal,
    void Function(TypeOfData data, IdPeer from) onData,
    Set<ErmesConnectionContext> skip, [
    ISignalErmes? ourSignal,
  ]) async {
    final wanted = advertisedFamilies(ourSignal, peer)
        .where((c) => !skip.contains(c));
    final infos = peerInfosFromSignal(peerSignal, peer, wanted);
    if (infos.isEmpty) {
      throw CoreException(
        'No common address family with $peer: our families '
        '${sockets.contexts.map((c) => c.label).toList()}, signal '
        'IPv4 ${peerSignal.ipv4}:${peerSignal.ipv4Port}, '
        'IPv6 ${peerSignal.ipv6}:${peerSignal.ipv6Port}',
      );
    }
    final created = <ErmesConnectionContext, ErmesPeer>{};
    for (final entry in infos.entries) {
      created[entry.key] = createFor(peer, peerSignal, entry, onData);
    }
    return initializeAll(created);
  }

  /// Our families that [ourSignal] advertises: a family we have a socket for
  /// but could not map via STUN is not dialed, since the peer cannot reach
  /// it. Falls back to every socket family when the signal maps none of them.
  List<ErmesConnectionContext> advertisedFamilies(
    ISignalErmes? ourSignal,
    IdPeer peer,
  ) {
    final all = sockets.contexts;
    if (ourSignal == null) {
      return all;
    }
    final mapped = peerInfosFromSignal(ourSignal, peer, all).keys.toList();
    return mapped.isEmpty ? all : mapped;
  }

  ErmesPeer createFor(
    IdPeer peer,
    ISignalErmes peerSignal,
    MapEntry<ErmesConnectionContext, ErmesPeerInfo> entry,
    void Function(TypeOfData data, IdPeer from) onData,
  ) {
    bookService.setAccount(
      AccountInfo<BookData>(account: peer, peerInfo: entry.value),
    );
    final ermesPeer =
        ErmesPeerFactory.create(peerConfigFor(peer, sockets.of(entry.key)))
          ..addOnMessageListener((data) => onData(data, peer));
    applySharedSecret(peer, peerSignal, ermesPeer, entry.value);
    return ermesPeer;
  }

  Future<Map<ErmesConnectionContext, ErmesPeer>> initializeAll(
    Map<ErmesConnectionContext, ErmesPeer> created,
  ) async {
    final ready = <ErmesConnectionContext, ErmesPeer>{};
    Object? failure;
    for (final entry in created.entries) {
      try {
        await entry.value.initialize(initiateKeyExchange: enableEncryption);
        ready[entry.key] = entry.value;
      } on Exception catch (e) {
        failure = e;
        await entry.value.dispose();
      }
    }
    if (ready.isEmpty) {
      throw CoreException('Failed to establish any Connection: $failure');
    }
    return ready;
  }

  /// Derives the ECDH shared-secret cipher from the peer's public key carried
  /// in [peerSignal] and makes it the cipher toward [peer]. Runs on every
  /// (re)dial; a superseded signal key stops being used for encryption.
  /// The key is bound to the address family of the dialed [peerInfo]; an
  /// in-band `newpubkey` on [ermesPeer] re-derives only that family (RFC 8.6).
  void applySharedSecret(
    IdPeer peer,
    ISignalErmes peerSignal,
    ErmesPeer ermesPeer,
    ErmesPeerInfo peerInfo,
  ) {
    if (cipherApplier case final applier? when enableEncryption) {
      final ctx = connectionContextOf(peerInfo);
      applier
        ..apply(peer, peerSignal.publicKey, ctx,
            idSignaling: peerSignal.idSignaling)
        ..listen(peer, ermesPeer.service, ctx);
    }
  }
}
