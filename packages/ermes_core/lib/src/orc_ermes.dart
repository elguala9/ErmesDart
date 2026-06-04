import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'ermes_connections_handler.dart';
import 'ermes_peer.dart';
import 'exceptions.dart';
import 'factories/ermes_connections_handler_factory.dart';
import 'orc_ermes_connection_opener.dart';

/// High-level orchestrator for managing multiple P2P Ermes connections.
///
/// Coordinates signaling, book service, individual `ErmesPeer` instances
/// and reconnection. The multi-step handshake lives in
/// [OrcConnectionOpener]; this class wires it together with the public
/// `IOrcErmes` surface (send, listeners, lifecycle, book / signaling
/// pass-throughs).
@isSingleton
class OrcErmes implements IOrcErmes<BookData> {
  OrcErmes({
    required this.signalingServer,
    required this.signalingHandler,
    required this.socket,
    IErmesBookService<BookData>? bookService,
    bool enableEncryption = true,
    int connectionTimeoutMs = 30000,
  })  : bookService = bookService ?? ErmesBookService(),
        _enableEncryption = enableEncryption,
        _connectionTimeoutMs = connectionTimeoutMs,
        connectionsHandler = ErmesConnectionsHandlerFactory.createHandler();

  OrcErmes.emptyForDI();

  @isInjected
  @protected
  late IErmesSignalingServer signalingServer;
  @isInjected
  @protected
  late IErmesSignalingHandler<ShspPeer> signalingHandler;
  @isInjected
  @protected
  late IShspSocket socket;
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

  static const int _maxReconnectAttempts = 3;

  final Map<IdPeer, ErmesPeer> _peers = {};
  final List<CallbackOnDataArrivedFrom> _messageCallbacks = [];
  final List<void Function(IdPeer)> _disconnectCallbacks = [];

  @override
  Future<void> openConnection(IdPeer peer) async {
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(peer)) {
      throw CoreException('Invalid peer public key format: $peer');
    }

    final existing = _peers[peer];
    if (existing != null && existing.isConnected()) {
      return;
    }
    if (existing != null) {
      _peers.remove(peer);
      await existing.dispose();
      await signalingHandler.softClearConnection(peer);
    }

    try {
      final opener = OrcConnectionOpener(
        signalingServer: signalingServer,
        signalingHandler: signalingHandler,
        socket: socket,
        bookService: bookService,
        enableEncryption: _enableEncryption,
        connectionTimeoutMs: _connectionTimeoutMs,
      );
      _peers[peer] = await opener.open(
        peer,
        _dispatchMessage,
        _handlePeerDisconnect,
      );
    } catch (e) {
      throw CoreException('Failed to open connection to peer $peer: $e');
    }
  }

  void _dispatchMessage(TypeOfData data, IdPeer from) {
    for (final cb in _messageCallbacks) {
      cb(data, from);
    }
  }

  @override
  Future<void> send(TypeOfDataExternal data, IdPeer peer) async {
    final ermesPeer = _peers[peer];
    if (ermesPeer == null) {
      throw CoreException(
        'Peer $peer is not connected. Call openConnection first.',
      );
    }
    try {
      await ermesPeer.send(data);
    } catch (e) {
      throw CoreException('Failed to send data to peer $peer: $e');
    }
  }

  @override
  Future<void> onMessage(CallbackOnDataArrivedFrom cb) async =>
      _messageCallbacks.add(cb);

  @override
  Future<void> closeConnection(IdPeer peer) async {
    final ermesPeer = _peers.remove(peer);
    if (ermesPeer == null) {
      return;
    }
    try {
      await ermesPeer.dispose();
      await signalingHandler.softClearConnection(peer);
    } catch (e) {
      throw CoreException('Failed to close connection to peer $peer: $e');
    }
  }

  @override
  Future<void> destroy({bool force = false}) async {
    try {
      for (final peer in _peers.values) {
        await peer.dispose(flushBeforeClose: !force);
      }
      _peers.clear();
      _messageCallbacks.clear();
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
  Future<void> save() async {
    try {
      await connectionsHandler.saveState();
    } catch (e) {
      throw CoreException('Failed to save connections state: $e');
    }
  }

  @override
  Future<List<IdPeer>> getConnections() async => _peers.keys.toList();

  @override
  Future<void> onDisconnect(void Function(IdPeer peer) cb) async =>
      _disconnectCallbacks.add(cb);

  Future<void> _handlePeerDisconnect(IdPeer peer, [int attempt = 1]) async {
    if (attempt > _maxReconnectAttempts) {
      for (final cb in _disconnectCallbacks) {
        cb(peer);
      }
      return;
    }
    await Future<void>.delayed(Duration(seconds: 1 << (attempt - 1)));
    try {
      await openConnection(peer);
    } on Exception catch (_) {
      await _handlePeerDisconnect(peer, attempt + 1);
    }
  }

  // ---- Book service pass-through -----------------------------------------

  @override
  Future<void> setAccount(AccountInfo<BookData> info) async =>
      bookService.setAccount(info);

  @override
  Future<void> updateAccount(AccountInfo<BookData> info) async =>
      bookService.updateAccount(info);

  @override
  Future<AccountInfo<BookData>> getAccount(IdAccountType a) async =>
      bookService.getAccount(a);

  @override
  Future<PaginationDto<AccountInfo<BookData>, IdAccountType>> getAccountList(
    IdAccountType cursor,
    int limit,
  ) async =>
      bookService.getAccountList(cursor, limit);

  @override
  Future<bool> deleteAccount(IdAccountType a) async =>
      bookService.deleteAccount(a);

  @override
  Future<void> clear() async => bookService.clear();

  @override
  Future<int> numberOfElements() async => bookService.numberOfElements();

  @override
  Future<List<IdAccountType>> listOfIds() async => bookService.listOfIds();

  @override
  Future<ErmesPeerInfo?> getPeerInfo(IdAccountType a) async =>
      bookService.getPeerInfo(a);

  // ---- Signaling server pass-through -------------------------------------

  @override
  Future<IdAccountType> getIdAccount() async => signalingServer.getIdAccount();

  @override
  Future<bool> isSignalingConnected() async => signalingServer.isConnected();

  @override
  Future<void> onSignalingError(void Function(Object err) cb) async =>
      signalingServer.onError(cb);

  @override
  Future<void> onSignalingClose(void Function() cb) async =>
      signalingServer.onClose(cb);
}
