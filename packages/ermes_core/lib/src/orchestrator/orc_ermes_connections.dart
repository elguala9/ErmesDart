import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart' show ShspPeer;

import '../peer_connection/ermes_connection_key.dart';
import '../peer_connection/ermes_peer_connections.dart';
import '../peer_connection/ermes_peer_connections_factory.dart';
import '../support/ermes_id_validator.dart';
import '../support/exceptions.dart';
import '../utility/utility.dart';
import 'orc_ermes_callbacks.dart';
import 'orc_ermes_connection_opener.dart';

/// Connection lifecycle of the orchestrator: one [ErmesPeerConnections]
/// aggregate per remote peer, holding one independent Connection per address
/// family (RFC sections 2 and 5).
mixin OrcErmesConnections on OrcErmesCallbacks
    implements IOrcErmes<BookData> {
  /// Signaling handler shared by every Connection.
  @protected
  IErmesSignalingHandler<ShspPeer> get signalingHandler;

  /// Connections per remote peer.
  @protected
  Map<IdPeer, ErmesPeerConnections> get connections;

  /// Builds a fresh opener wired to the orchestrator's collaborators.
  @protected
  OrcConnectionOpener newConnectionOpener();

  @override
  Future<void> openConnection(IdPeer peer) async {
    ErmesIdValidator.validatePublicKey(peer);
    final opener = newConnectionOpener();
    final held = connections[peer] ??
        ErmesPeerConnectionsFactory.create(
          ErmesPeerConnectionsInput(peer: peer),
        );
    if (held.isFullyConnected()) {
      // Keep our advertised endpoint fresh even when every Connection is
      // live: a rendezvous / re-dial loop relies on every openConnection
      // republishing our current NAT mapping. Best-effort.
      await refreshOwnSignal(opener, peer);
      await onAlreadyConnected(peer);
      return;
    }
    if ((await held.removeDisconnected()).isNotEmpty) {
      await signalingHandler.softClearConnection(peer);
    }
    await guardCoreOp('Failed to open connection to peer $peer', () async {
      await _dialMissing(opener, peer, held);
    });
  }

  /// Dials the families of [held] that are not live. A failure leaves the
  /// live families untouched and is only reported when none is left.
  Future<void> _dialMissing(
    OrcConnectionOpener opener,
    IdPeer peer,
    ErmesPeerConnections held,
  ) async {
    try {
      final opened = await opener.open(
        peer,
        dispatchMessage,
        handlePeerDisconnect,
        skip: held.contexts.toSet(),
      );
      opened.forEach(held.add);
    } on Exception {
      if (!held.isConnected()) {
        rethrow;
      }
    }
    connections[peer] = held;
  }

  /// Hook run when every Connection to [peer] is already live.
  @protected
  Future<void> onAlreadyConnected(IdPeer peer) async {}

  /// Best-effort republish of our signal for [peer] (broadcast when `null`).
  @protected
  Future<void> refreshOwnSignal(
    OrcConnectionOpener opener,
    IdPeer? peer,
  ) async {
    try {
      await opener.publishOwnSignal(peer);
    } on Object {
      // Best-effort: retried on the next window.
    }
  }

  @override
  Future<void> send(TypeOfDataExternal data, IdPeer peer) =>
      sendOverFamily(data, peer);

  /// Sends [data] to [peer] over [family], or over the preferred live family
  /// when omitted. Families never fail over to each other once chosen.
  Future<void> sendOverFamily(
    TypeOfDataExternal data,
    IdPeer peer, {
    ErmesConnectionContext? family,
  }) async {
    ErmesIdValidator.validatePublicKey(peer);
    final held = connections[peer];
    if (held == null) {
      throw CoreException(
        'Peer $peer is not connected. Call openConnection first.',
      );
    }
    await guardCoreOp(
      'Failed to send data to peer $peer',
      () => held.send(data, over: family),
    );
  }

  @override
  Future<void> closeConnection(IdPeer peer) async {
    final held = connections.remove(peer);
    if (held == null) {
      return;
    }
    await guardCoreOp('Failed to close connection to peer $peer', () async {
      await held.dispose();
      await signalingHandler.softClearConnection(peer);
    });
  }

  /// Closes only the [family] Connection to [peer]; the other family stays
  /// open and usable.
  Future<void> closeFamily(IdPeer peer, ErmesConnectionContext family) async {
    final held = connections[peer];
    if (held != null && held.has(family)) {
      await guardCoreOp(
        'Failed to close ${family.label} connection to peer $peer',
        () => held.remove(family),
      );
    }
  }

  @override
  Future<List<IdPeer>> getConnections() async => connections.keys.toList();

  /// Keys of every Connection held: one per peer and address family.
  List<ErmesConnectionKey> getConnectionKeys() =>
      [for (final held in connections.values) ...held.keys];
}
