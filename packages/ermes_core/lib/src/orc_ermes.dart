import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'ermes_connections_handler.dart';
import 'ermes_peer.dart';
import 'exceptions.dart';
import 'factories/ermes_connections_handler_factory.dart';
import 'orc_ermes_callbacks.dart';
import 'orc_ermes_connection_opener.dart';
import 'orc_ermes_passthrough.dart';
import 'utility.dart';
import 'validation/ermes_id_validator.dart';

/// High-level orchestrator for multiple P2P Ermes connections.
///
/// Wires the connection lifecycle (open, send, close, destroy, save) to the
/// handshake ([OrcConnectionOpener]), message callbacks / reconnection
/// ([OrcErmesCallbacks]) and book / signaling pass-throughs
/// ([OrcErmesPassthrough]).
@isSingleton
class OrcErmes
    with OrcErmesCallbacks, OrcErmesPassthrough
    implements IOrcErmes<BookData> {
  OrcErmes({
    required this.signalingServer,
    required this.signalingHandler,
    required this.socket,
    IErmesBookService<BookData>? bookService,
    bool enableEncryption = true,
    int connectionTimeoutMs = 30000,
  }) : bookService = bookService ?? ErmesBookService(),
       _enableEncryption = enableEncryption,
       _connectionTimeoutMs = connectionTimeoutMs,
       connectionsHandler = ErmesConnectionsHandlerFactory.createHandler();

  OrcErmes.emptyForDI();

  @override
  @isInjected
  @protected
  late IErmesSignalingServer signalingServer;
  @isInjected
  @protected
  late IErmesSignalingHandler<ShspPeer> signalingHandler;
  @isInjected
  @protected
  late IShspSocket socket;
  @override
  @isInjected
  @protected
  late IErmesBookService<BookData> bookService;
  @isInjected
  @protected
  late ErmesConnectionsHandler connectionsHandler;
  @isOptionalParameter
  bool _enableEncryption = true;
  @isOptionalParameter
  int _connectionTimeoutMs = 30000;

  final Map<IdPeer, ErmesPeer> _peers = {};

  @override
  Future<void> openConnection(IdPeer peer) async {
    ErmesIdValidator.validatePublicKey(peer);

    final opener = OrcConnectionOpener(
      signalingServer: signalingServer,
      signalingHandler: signalingHandler,
      socket: socket,
      bookService: bookService,
      enableEncryption: _enableEncryption,
      connectionTimeoutMs: _connectionTimeoutMs,
    );

    final existing = _peers[peer];
    if (existing != null && existing.isConnected()) {
      // Keep our advertised endpoint fresh even when a connection object
      // already exists and reports connected: a rendezvous / re-dial loop
      // relies on every openConnection republishing our current NAT mapping.
      // Without it, a peer whose external port changed (hard restart, long
      // outage) stops advertising, its relay signal ages past the stale
      // threshold, and the counterpart rejects it — so neither side can
      // re-punch. Best-effort: a transient relay failure must not fail a call
      // that is otherwise a no-op on a live connection.
      await _refreshOwnSignal(opener, peer);
      return;
    }
    if (existing != null) {
      _peers.remove(peer);
      await existing.dispose();
      await signalingHandler.softClearConnection(peer);
    }

    await guardCoreOp('Failed to open connection to peer $peer', () async {
      _peers[peer] = await opener.open(
        peer,
        dispatchMessage,
        handlePeerDisconnect,
      );
    });
  }

  /// Republishes our owner signal for [peer] as a best-effort refresh on the
  /// already-connected fast path. A relay hiccup here must not fail an
  /// openConnection that is otherwise a no-op on a live connection.
  Future<void> _refreshOwnSignal(
    OrcConnectionOpener opener,
    IdPeer peer,
  ) async {
    try {
      await opener.publishOwnSignal(peer);
    } on Object {
      // Best-effort: the connection is already live; a failed refresh only
      // means this window's re-advertise is skipped, retried next window.
    }
  }

  @override
  Future<void> send(TypeOfDataExternal data, IdPeer peer) async {
    ErmesIdValidator.validatePublicKey(peer);
    final ermesPeer = _peers[peer];
    if (ermesPeer == null) {
      throw CoreException(
        'Peer $peer is not connected. Call openConnection first.',
      );
    }
    await guardCoreOp(
      'Failed to send data to peer $peer',
      () => ermesPeer.send(data),
    );
  }

  @override
  Future<void> closeConnection(IdPeer peer) async {
    final ermesPeer = _peers.remove(peer);
    if (ermesPeer == null) {
      return;
    }
    await guardCoreOp('Failed to close connection to peer $peer', () async {
      await ermesPeer.dispose();
      await signalingHandler.softClearConnection(peer);
    });
  }

  @override
  Future<void> destroy({bool force = false}) async {
    try {
      for (final peer in _peers.values) {
        await peer.dispose(flushBeforeClose: !force);
      }
      _peers.clear();
      clearMessageCallbacks();
      await signalingHandler.destroy();
      await signalingServer.destroy();
      bookService.destroy();
      connectionsHandler.clearAllConnections();
    } catch (e) {
      if (!force) {
        throw CoreException('Failed to destroy OrcErmes: $e');
      }
    }
  }

  @override
  Future<void> save() async => guardCoreOp(
    'Failed to save connections state',
    () => connectionsHandler.saveState(),
  );

  @override
  Future<List<IdPeer>> getConnections() async => _peers.keys.toList();
}
