import 'dart:async';
import 'dart:io';

import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'ermes_connections_handler.dart';
import 'ermes_peer.dart';
import 'factories/ermes_connections_handler_factory.dart';
import 'factories/ermes_peer_factory.dart';

/// High-level orchestrator for managing multiple P2P Ermes connections.
///
/// OrcErmes simplifies the management of multiple peer connections by
/// coordinating:
/// - Signaling server for peer discovery and address exchange
/// - Signaling handler for STUN + SHSP handshakes
/// - Book service for peer information storage
/// - Individual ErmesPeer instances for each connection
/// - Connection handler for lifecycle management
///
/// Usage:
/// ```dart
/// final orc = OrcErmes.fromContract(
///   contract: signalingContract,
///   accountId: myAccountId,
///   socket: myShspSocket,
///   stunHandler: myStunHandler,
/// );
///
/// await orc.openConnection(bobPeerId);
/// await orc.send(myData, bobPeerId);
/// orc.onMessage((data, peerId) => print('From $peerId: $data'));
/// ```
@isSingleton
class OrcErmes implements IOrcErmes {
  /// Creates an OrcErmes instance with explicit dependency injection.
  ///
  /// This constructor is useful for testing or when you need fine-grained
  /// control over the components.
  ///
  /// [signalingServer] The server for peer discovery
  /// [signalingHandler] Handler for STUN and SHSP protocol
  /// [socket] The transport socket
  /// [bookService] Optional peer address book (defaults to singleton)
  /// [enableEncryption] Enable ECDH encryption for messages (default: true)
  /// [connectionTimeoutMs] Connection timeout in milliseconds
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

  /// Creates an OrcErmes instance from a SignalingContract.
  ///
  /// This factory constructor handles the creation of all internal components
  /// and is recommended for most use cases.
  ///
  /// [contract] The deployed SignalingContract instance
  /// [accountId] The account ID of the current user
  /// [stunShspHandler] Combined STUN + SHSP handler (provides socket and
  /// NAT traversal)
  /// [overridePort] Optional port to use in STUN fallback (for Docker testing)
  /// [enableEncryption] Enable ECDH encryption (default: true)
  /// [connectionTimeoutMs] Connection timeout in milliseconds (default: 30000)
  factory OrcErmes.fromContract({
    required SignalingContract contract,
    required IdAccountType accountId,
    required IStunShspHandler stunShspHandler,
    int? overridePort,
    bool enableEncryption = true,
    int connectionTimeoutMs = 30000,
  }) {
    final socket = stunShspHandler.ipv4ShspSocket;
    final bookService = ErmesBookService();
    final signalingServer =
        ErmesSignalingServerFactory.createServer(contract, accountId);
    final signalingHandler = ErmesSignalingHandler.create(
      stunShspHandler,
      socket,
      bookService,
      overridePort: overridePort,
    );

    return OrcErmes(
      signalingServer: signalingServer,
      signalingHandler: signalingHandler,
      socket: socket,
      bookService: bookService,
      enableEncryption: enableEncryption,
      connectionTimeoutMs: connectionTimeoutMs,
    );
  }

  // ========================================================================
  // Internal State
  // ========================================================================

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

  /// Map of peer IDs to their corresponding ErmesPeer instances
  final Map<IdPeer, ErmesPeer> _peers = {};

  /// List of callbacks to invoke when data arrives from any peer
  final List<CallbackOnDataArrivedFrom> _messageCallbacks = [];

  /// List of callbacks called when a peer disconnects after exhausting retries
  final List<void Function(IdPeer)> _disconnectCallbacks = [];

  // ========================================================================
  // IOrcErmes Implementation
  // ========================================================================

  @override
  Future<void> openConnection(IdPeer peer) async {
    // Validate Ethereum address format (40 hex chars, optional 0x prefix)
    if (!RegExp(r'^(0x)?[0-9a-fA-F]{40}$').hasMatch(peer)) {
      throw Exception('Invalid peer address format: $peer');
    }

    final existingPeer = _peers[peer];

    // Already connected — nothing to do
    if (existingPeer != null && existingPeer.isConnected()) return;

    // Stale/disconnected peer — clean up before reconnecting
    if (existingPeer != null) {
      _peers.remove(peer);
      await existingPeer.dispose();
      await signalingHandler.softClearConnection(peer);
    }

    try {
      // 1. Create and publish our signal first
      final ourSignal = await signalingHandler.createSignal(peer);
      print('[OrcErmes] Signal created for $peer, publishing...');
      await signalingServer.setSignal(ourSignal, peer);
      print('[OrcErmes] Signal published for $peer');

      // 2. Wait for peer's signal (with retries)
      ISignalErmes? peerSignal;
      int signalAttempts = 0;
      int maxAttempts = 60;
      while (peerSignal == null && signalAttempts < maxAttempts) {
        signalAttempts++;
        try {
          peerSignal = await signalingServer.getSignal(peer);
          if (peerSignal != null && !peerSignal.isExpired()) {
            if (signalAttempts > 1) {
              print('[OrcErmes] Found signal from $peer after $signalAttempts attempts');
            }
            break;
          }
          if (peerSignal != null && peerSignal.isExpired()) {
            print('[OrcErmes] Signal from $peer is expired, retrying...');
            peerSignal = null;
          }
        } catch (e) {
          // Retry on error (signal not yet posted by remote peer)
          if (signalAttempts % 10 == 0) {
            print('[OrcErmes] Waiting for signal from $peer (attempt $signalAttempts): $e');
          }
        }
        if (peerSignal == null) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }

      if (peerSignal == null) {
        throw Exception('Timeout waiting for peer signal after $maxAttempts attempts');
      }

      // 3. Extract peer information from signal
      final peerInfo = _peerInfoFromSignal(peerSignal, peer);

      // 4. Store peer info in book service
      bookService.setAccount(
        AccountInfo<BookData>(
          account: peer,
          peerInfo: peerInfo,
        ),
      );

      // 5. Create ErmesPeer instance
      // (rest of the code unchanged)
      final config = ErmesPeerConfig(
        remotePeerId: peer,
        socket: socket,
        signalingHandler: signalingHandler,
        ermesBookService: bookService,
        idHandler: IdHandlerServiceFactory.createDefault(),
        timeoutMs: _connectionTimeoutMs,
        enableEncryption: _enableEncryption,
      );

      final ermesPeer = ErmesPeerFactory.create(config)
        ..addOnMessageListener((data) {
          for (final callback in _messageCallbacks) {
            callback(data, peer);
          }
        });

      // 7. Initialize the peer connection
      await ermesPeer.initialize(initiateKeyExchange: _enableEncryption);

      // 8. Register auto-reconnect on remote-initiated disconnect
      ermesPeer.addOnDisconnectListener(
        () => unawaited(_handlePeerDisconnect(peer)),
      );

      // 9. Store the peer
      _peers[peer] = ermesPeer;
    } catch (e) {
      throw Exception('Failed to open connection to peer $peer: $e');
    }
  }

  @override
  Future<void> send(TypeOfDataExternal data, IdPeer peer) async {
    final ermesPeer = _peers[peer];
    if (ermesPeer == null) {
      throw Exception(
        'Peer $peer is not connected. Call openConnection first.',
      );
    }

    try {
      await ermesPeer.send(data);
    } catch (e) {
      throw Exception('Failed to send data to peer $peer: $e');
    }
  }

  @override
  Future<void> onMessage(CallbackOnDataArrivedFrom callbackOnData) async {
    _messageCallbacks.add(callbackOnData);
  }

  @override
  Future<void> closeConnection(IdPeer peer) async {
    final ermesPeer = _peers.remove(peer);
    if (ermesPeer != null) {
      try {
        await ermesPeer.dispose();
        await signalingHandler.softClearConnection(peer);
      } catch (e) {
        throw Exception('Failed to close connection to peer $peer: $e');
      }
    }
  }

  @override
  Future<void> destroy({bool force = false}) async {
    try {
      // Close all peer connections
      for (final peer in _peers.values) {
        await peer.dispose(flushBeforeClose: !force);
      }
      _peers.clear();

      // Clear message callbacks
      _messageCallbacks.clear();

      // Destroy signaling components
      await signalingHandler.destroy();
      await signalingServer.destroy();

      // Clear connections handler
      connectionsHandler.clearAllConnections();
    } catch (e) {
      if (!force) {
        throw Exception('Failed to destroy OrcErmes: $e');
      }
    }
  }

  @override
  Future<void> save() async {
    try {
      await connectionsHandler.saveState();
    } catch (e) {
      throw Exception('Failed to save connections state: $e');
    }
  }

  @override
  Future<List<IdPeer>> getConnections() async => _peers.keys.toList();

  @override
  Future<void> onDisconnect(void Function(IdPeer peer) callback) async {
    _disconnectCallbacks.add(callback);
  }

  /// Handles a remote-initiated peer disconnect with exponential backoff retry.
  ///
  /// Attempts [_maxReconnectAttempts] reconnections with delays of 1s, 2s, 4s.
  /// If all attempts fail, fires the [_disconnectCallbacks].
  /// Cleanup of the stale peer is delegated to [openConnection].
  Future<void> _handlePeerDisconnect(IdPeer peer, [int attempt = 1]) async {
    if (attempt > _maxReconnectAttempts) {
      for (final cb in _disconnectCallbacks) {
        cb(peer);
      }
      return;
    }

    // Exponential backoff: 1s, 2s, 4s
    await Future<void>.delayed(Duration(seconds: 1 << (attempt - 1)));

    try {
      await openConnection(peer);
    } on Exception catch (_) {
      await _handlePeerDisconnect(peer, attempt + 1);
    }
  }

  // ========================================================================
  // Helper Methods
  // ========================================================================

  /// Extracts ErmesPeerInfo from an ISignalErmes signal.
  ///
  /// Prefers IPv6 address, falls back to IPv4 if IPv6 is not available.
  /// Throws an exception if neither IPv6 nor IPv4 is valid.
  ErmesPeerInfo _peerInfoFromSignal(
    ISignalErmes signal,
    IdAccountType peerId,
  ) {
    String? host;
    int? port;

    // Prefer IPv6
    if (signal.ipv6.isNotEmpty && signal.ipv6 != '::') {
      host = signal.ipv6;
      port = int.tryParse(signal.ipv6Port);
    }

    // Fall back to IPv4
    if (host == null || host.isEmpty) {
      if (signal.ipv4.isNotEmpty) {
        host = signal.ipv4;
        port = int.tryParse(signal.ipv4Port);
      }
    }

    // Validate
    if (host == null || host.isEmpty || port == null || port <= 0) {
      throw Exception(
        'Invalid peer signal for $peerId: no valid IP address. '
        'IPv6: ${signal.ipv6}:${signal.ipv6Port}, '
        'IPv4: ${signal.ipv4}:${signal.ipv4Port}',
      );
    }

    return ErmesPeerInfo(
      address: InternetAddress(host),
      port: port,
      id: peerId,
    );
  }
}
