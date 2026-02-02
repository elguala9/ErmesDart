import 'dart:async';
import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';

/// Instance di un peer nel framework di test multi-peer
@includeInBarrelFile
class PeerInstance {
  PeerInstance({
    required this.id,
    required this.idHandler,
  });

  /// ID univoco del peer
  final String id;

  /// ID Handler per questo peer
  final IIdHandlerService idHandler;

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
    try {
      service?.close();
    } on Exception {
      // Ignora errori durante cleanup
    }

    activeConnections.clear();
  }
}

/// Framework per coordinare test multi-peer
///
/// Questo framework fornisce utility per creare e gestire multiple istanze di peer
/// in test, usando le factories per creare componenti.
///
/// Utilizzo:
/// ```dart
/// final framework = MultiPeerTestFramework();
/// await framework.createPeers(2, signalingServer: server);
///
/// // Accedi ai peer
/// final peer0 = framework.peers[0];
/// final peer1 = framework.peers[1];
///
/// // Cleanup
/// await framework.cleanup();
/// ```
@includeInBarrelFile
class MultiPeerTestFramework {
  MultiPeerTestFramework();

  /// Lista di tutti i peer nel test
  final List<PeerInstance> peers = [];

  /// Mappa di peer ID -> PeerInstance per lookup rapido
  final Map<String, PeerInstance> _peersMap = {};

  /// Crea N peer usando le factories
  ///
  /// Ogni peer viene creato con:
  /// - IdHandler (per gestione ID)
  ///
  /// Service e Repository dovranno essere configurati dal test
  Future<void> createPeers(
    int count, {
    required dynamic signalingServer,
  }) async {
    for (var i = 0; i < count; i++) {
      final peerId = 'peer-$i';

      // Usa IdHandlerServiceFactory per creare ID handler
      final idHandler = IdHandlerServiceFactory.createDefault();

      final peerInstance = PeerInstance(
        id: peerId,
        idHandler: idHandler,
      );

      peers.add(peerInstance);
      _peersMap[peerId] = peerInstance;
    }
  }

  /// Connette due peer
  ///
  /// I dettagli della connessione saranno implementati nei test specifici
  Future<void> connectPeers(String peer1Id, String peer2Id) async {
    // Verifica che entrambi i peer esistano
    _getPeerOrThrow(peer1Id);
    _getPeerOrThrow(peer2Id);

    // Placeholder per logica di connessione
    // Sarà implementato nei test specifici
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

    peer.service!.onMessageData(callback);
  }

  /// Ottiene un peer per ID
  PeerInstance? getPeer(String peerId) => _peersMap[peerId];

  /// Cleanup di tutti i peer
  Future<void> cleanup() async {
    for (final peer in peers) {
      try {
        await peer.dispose();
      } on Exception {
        // Ignora errori durante cleanup
      }
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
