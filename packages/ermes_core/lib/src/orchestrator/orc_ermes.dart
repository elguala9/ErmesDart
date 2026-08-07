import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../peer_connection/ermes_connections_handler.dart';
import '../peer_connection/ermes_connections_handler_factory.dart';
import '../peer_connection/ermes_peer.dart';
import '../support/ermes_id_validator.dart';
import '../support/exceptions.dart';
import '../utility/utility.dart';
import 'orc_ermes_callbacks.dart';
import 'orc_ermes_connection_opener.dart';
import 'orc_ermes_passthrough.dart';

/// Default time budget, in milliseconds, for establishing a connection.
const int defaultConnectionTimeoutMs = 30000;

/// High-level orchestrator for multiple P2P Ermes connections.
///
/// Wires the connection lifecycle (open, send, close, destroy, save) to the
/// handshake ([OrcConnectionOpener]), message callbacks / reconnection
/// ([OrcErmesCallbacks]) and book / signaling pass-throughs
/// ([OrcErmesPassthrough]).
@dependencyInjectable
class OrcErmes
    with OrcErmesCallbacks, OrcErmesPassthrough
    implements IOrcErmes<BookData> {
  /// Creates an orchestrator over the given signaling stack and socket.
  ///
  /// The socket is resolved under the `ipv4` subkey: shsp registers one per
  /// address family, and this orchestrator drives the IPv4-primary path.
  ///
  /// [enableEncryption] and [connectionTimeoutMs] are nullable so dependency
  /// injection can leave them unregistered and still get the defaults.
  OrcErmes({
    required this.signalingServer,
    required this.signalingHandler,
    @Subkey('ipv4') required this.socket,
    IErmesBookService<BookData>? bookService,
    ErmesConnectionsHandler? connectionsHandler,
    IKeyExchange? keyExchange,
    bool? enableEncryption,
    int? connectionTimeoutMs,
  }) : bookService = bookService ?? ErmesBookService(),
       _keyExchange = keyExchange,
       connectionsHandler = connectionsHandler ??
           ErmesConnectionsHandlerFactory.createHandler(),
       _enableEncryption = enableEncryption ?? true,
       _connectionTimeoutMs =
           connectionTimeoutMs ?? defaultConnectionTimeoutMs;

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory OrcErmes.dependencyInjectionFactory({
    String key = 'default',
    // ignore: avoid_unused_constructor_parameters
    String subkey = 'default',
  }) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final signalingServer = RegistryManager.instance
        .getInstance<IErmesSignalingServer>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final signalingHandler = RegistryManager.instance
        .getInstance<IErmesSignalingHandler<ShspPeer>>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final socket = RegistryManager.instance.getInstance<IShspSocket>(
      key: key,
      subkey: 'ipv4',
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final bookService = RegistryManager.instance
        .tryGetInstance<IErmesBookService<BookData>>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final connectionsHandler = RegistryManager.instance
        .tryGetInstance<ErmesConnectionsHandler>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final keyExchange = RegistryManager.instance
        .tryGetInstance<IKeyExchange>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final enableEncryption = RegistryManager.instance.tryGetInstance<bool>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final connectionTimeoutMs = RegistryManager.instance.tryGetInstance<int>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND

    // GENERATED CODE - DO NOT MODIFY BY HAND
    return OrcErmes(
      signalingServer: signalingServer,
      signalingHandler: signalingHandler,
      socket: socket, // GENERATED CODE - DO NOT MODIFY BY HAND
      bookService: bookService, // GENERATED CODE - DO NOT MODIFY BY HAND
      connectionsHandler: connectionsHandler,
      keyExchange: keyExchange, // GENERATED CODE - DO NOT MODIFY BY HAND
      enableEncryption: enableEncryption,
      connectionTimeoutMs: connectionTimeoutMs,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  @override
  @protected
  final IErmesSignalingServer signalingServer;
  @protected
  final IErmesSignalingHandler<ShspPeer> signalingHandler;
  @protected
  final IShspSocket socket;
  @override
  @protected
  final IErmesBookService<BookData> bookService;
  @protected
  final ErmesConnectionsHandler connectionsHandler;
  /// This peer's key pair, forwarded to every [OrcConnectionOpener] so the
  /// per-peer shared secrets can be derived. Required when encryption is on.
  final IKeyExchange? _keyExchange;
  final bool _enableEncryption;
  final int _connectionTimeoutMs;

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
      keyExchange: _keyExchange,
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
    connectionsHandler.saveState,
  );

  @override
  Future<List<IdPeer>> getConnections() async => _peers.keys.toList();
}
