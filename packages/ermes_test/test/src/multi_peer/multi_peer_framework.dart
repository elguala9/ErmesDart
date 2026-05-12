import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../test_helpers/in_memory_signaling.dart';
import '../test_signaling_helper.dart';

/// Instance di un peer nel framework di test multi-peer
class PeerInstance {
  PeerInstance({
    required this.id,
    required this.idHandler,
    required this.accountId,
    this.signalingSetup,
    this.signalingServer,
    this.signalingHandler,
    this.rawSocket,
    this.orc,
  });

  /// ID univoco del peer
  final String id;

  /// Account ID per signaling (chiave Nostr o mock)
  final String accountId;

  /// ID Handler per questo peer
  final IIdHandlerService idHandler;

  /// Setup di signaling Nostr per questo peer
  final TestSignalingSetup? signalingSetup;

  /// Signaling server condiviso (opzionale, default: proprio)
  final IErmesSignalingServer? signalingServer;

  /// Signaling handler condiviso (opzionale, default: proprio)
  final IErmesSignalingHandler<ShspPeer>? signalingHandler;

  /// Raw socket (per in-memory mode)
  final RawDatagramSocket? rawSocket;

  /// OrcErmes (per in-memory mode)
  final OrcErmes? orc;

  /// Service principale per scambio messaggi
  IErmesService? service;

  /// Repository principale per scambio messaggi
  IErmesRepository? repository;

  /// Connessioni attive da questo peer a altri peer
  final Map<String, IErmesConnection> activeConnections = {};

  /// Registra una connessione verso un altro peer
  void registerConnection(String toPeerId, IErmesConnection connection) {
    activeConnections[toPeerId] = connection;
  }

  /// Cleanup del peer
  Future<void> dispose() async {
    if (orc != null) {
      await orc!.destroy();
    }
    service?.close();
    await signalingSetup?.dispose();
    rawSocket?.close();
    activeConnections.clear();
  }
}

/// Framework per coordinare test multi-peer con signaling Nostr reale
/// o in-memory.
///
/// Ogni peer viene creato con:
/// - Chiavi Nostr univoche generate (real mode) o accountId fittizie
/// - Connessione WebSocket a un relay Nostr (real mode) o in-memory
/// - ErmesSignalingServer + ErmesSignalingHandler
/// - IdHandler per gestione ID
///
/// In in-memory mode non c'è dipendenza da relay Nostr esterni.
///
/// Utilizzo:
/// ```dart
/// final framework = MultiPeerTestFramework();
/// await framework.createPeers(2, useInMemorySignaling: true);
///
/// // Accedi ai peer
/// final peer0 = framework.peers[0];
/// final peer1 = framework.peers[1];
///
/// // Connetti due peer
/// await framework.connectPeers('peer-0', 'peer-1');
///
/// // Cleanup
/// await framework.cleanup();
/// ```
class MultiPeerTestFramework {
  MultiPeerTestFramework();

  /// Lista di tutti i peer nel test
  final List<PeerInstance> peers = [];

  /// Mappa di peer ID -> PeerInstance per lookup rapido
  final Map<String, PeerInstance> _peersMap = {};

  /// Store condiviso per segnali in-memory (se in uso)
  Map<String, List<int>>? _inMemoryStore;

  /// Subscriptions condivise per segnali in-memory (se in uso)
  Map<String, List<InMemorySubscription>>? _inMemorySubscriptions;

  /// Crea N peer.
  ///
  /// Con [useInMemorySignaling] = true (default) usa signaling in-memory
  /// senza dipendenza da relay Nostr esterno.
  ///
  /// Con [useInMemorySignaling] = false usa signaling Nostr reale
  /// via [relayUrl] (default: wss://relay.damus.io).
  Future<void> createPeers(
    int count, {
    bool useInMemorySignaling = true,
    String relayUrl = 'wss://relay.damus.io',
  }) async {
    if (useInMemorySignaling) {
      await _createPeersInMemory(count);
    } else {
      await _createPeersWithRelay(count, relayUrl: relayUrl);
    }
  }

  Future<void> _createPeersWithRelay(
    int count, {
    String relayUrl = 'wss://relay.damus.io',
  }) async {
    final setups = await createTestSignalingSetups(
      count: count,
      relayUrl: relayUrl,
    );

    for (var i = 0; i < count; i++) {
      final setup = setups[i];
      final peerId = 'peer-$i';
      final idHandler = IdHandlerServiceFactory.createDefault();

      final peerInstance = PeerInstance(
        id: peerId,
        idHandler: idHandler,
        accountId: setup.accountId,
        signalingSetup: setup,
        signalingServer: setup.signalingServer,
        signalingHandler: setup.signalingHandler,
      );

      peers.add(peerInstance);
      _peersMap[peerId] = peerInstance;
    }
  }

  Future<void> _createPeersInMemory(int count) async {
    _inMemoryStore = {};
    _inMemorySubscriptions = {};

    for (var i = 0; i < count; i++) {
      final peerId = 'peer-$i';
      // 64-char hex account ID (compatible with OrcErmes validation)
      final accountId = _makeHexAccountId(i);
      final idHandler = IdHandlerServiceFactory.createDefault();

      final peer = await createInMemoryPeer(
        accountId: accountId,
        store: _inMemoryStore!,
        subscriptions: _inMemorySubscriptions!,
      );

      final peerInstance = PeerInstance(
        id: peerId,
        idHandler: idHandler,
        accountId: accountId,
        signalingServer: peer.server,
        signalingHandler: peer.handler,
        rawSocket: peer.raw,
        orc: peer.orc,
      );

      peers.add(peerInstance);
      _peersMap[peerId] = peerInstance;
    }
  }

  /// Generates a 64-char hex account ID from an integer.
  String _makeHexAccountId(int value) {
    final hex = value.toRadixString(16);
    return hex.padLeft(64, '0');
  }

  /// Connette due peer via scambio di segnali.
  ///
  /// Funziona sia in real mode (via Nostr relay) che in in-memory mode.
  Future<void> connectPeers(
    String peer1Id,
    String peer2Id, {
    int timeoutMs = 30000,
  }) async {
    final peer1 = _getPeerOrThrow(peer1Id);
    final peer2 = _getPeerOrThrow(peer2Id);

    final server1 = peer1.signalingServer;
    final server2 = peer2.signalingServer;
    final handler1 = peer1.signalingHandler;

    if (server1 == null || server2 == null || handler1 == null) {
      throw StateError(
        'Signaling not initialized. Call createPeers() first.',
      );
    }

    final peer2AccountId = peer2.accountId;
    final peer1AccountId = peer1.accountId;

    // Peer 1: pubblica il proprio segnale
    final signal1 = await handler1.createSignal(peer2Id);
    await server1.setSignal(signal1, peer2AccountId);

    // Peer 2: pubblica il proprio segnale
    final handler2 = peer2.signalingHandler!;
    final signal2 = await handler2.createSignal(peer1Id);
    await server2.setSignal(signal2, peer1AccountId);

    // Reciproca sottoscrizione ai segnali
    server1.onSignal((data) {}, peer2AccountId);
    server2.onSignal((data) {}, peer1AccountId);
  }

  /// Invia messaggio da un peer all'altro
  void sendMessage(
    String fromId,
    String toId,
    Uint8List data,
  ) {
    final sender = _getPeerOrThrow(fromId);

    if (sender.service == null) {
      throw StateError('Service non inizializzato per peer $fromId');
    }

    sender.service!.send(data);
  }

  /// Registra un listener per i messaggi ricevuti da un peer
  void onPeerMessageReceived(
    String peerId,
    void Function(Uint8List) callback,
  ) {
    final peer = _getPeerOrThrow(peerId);

    if (peer.service == null) {
      throw StateError('Service non inizializzato per peer $peerId');
    }

    peer.service!.addOnMessageDataListener(callback);
  }

  /// Ottiene un peer per ID
  PeerInstance? getPeer(String peerId) => _peersMap[peerId];

  /// Cleanup di tutti i peer (chiude relay Nostr e socket)
  Future<void> cleanup() async {
    for (final peer in peers) {
      await peer.dispose();
    }
    peers.clear();
    _peersMap.clear();
  }

  /// Getter privato che lancia eccezione se il peer non esiste
  PeerInstance _getPeerOrThrow(String peerId) {
    final peer = _peersMap[peerId];
    if (peer == null) {
      throw StateError('Peer $peerId non trovato nel framework');
    }
    return peer;
  }
}
