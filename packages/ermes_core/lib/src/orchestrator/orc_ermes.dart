import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../peer_connection/ermes_connections_handler.dart';
import '../peer_connection/ermes_connections_handler_factory.dart';
import '../peer_connection/ermes_peer_connections.dart';
import 'ermes_signal_last_seen_store.dart';
import 'orc_ermes_callbacks.dart';
import 'orc_ermes_connection_opener.dart';
import 'orc_ermes_connections.dart';
import 'orc_ermes_family_access.dart';
import 'orc_ermes_key_rotation.dart';
import 'orc_ermes_maintenance.dart';
import 'orc_ermes_passthrough.dart';
import 'orc_ermes_signal_republish.dart';
import 'orc_family_sockets.dart';
import 'orc_signal_cipher_applier.dart';
import 'orc_signal_republish_settings.dart';
import 'orc_symmetric_nat_detector.dart';
part 'orc_ermes_registry.dart';

/// Default time budget, in milliseconds, for establishing a connection.
const int defaultConnectionTimeoutMs = 30000;

/// High-level orchestrator for multiple P2P Ermes connections: wires the
/// connection lifecycle to the handshake ([OrcConnectionOpener]), callbacks
/// ([OrcErmesCallbacks]) and pass-throughs ([OrcErmesPassthrough]).
@dependencyInjectable
class OrcErmes
    with
        OrcErmesCallbacks,
        OrcErmesPassthrough,
        OrcErmesConnections,
        OrcErmesFamilyAccess,
        OrcErmesMaintenance,
        OrcErmesKeyRotation,
        OrcErmesSignalRepublish
    implements IOrcErmes<BookData> {
  /// Creates an orchestrator over the given signaling stack and sockets
  /// (`ipv4` / `ipv6` subkeys, each optional but at least one required; one
  /// Connection per family available on both peers). Nullable parameters
  /// let dependency injection leave them unregistered and get the defaults.
  OrcErmes({
    required this.signalingServer,
    required this.signalingHandler,
    @Subkey('ipv4') IShspSocket? socket,
    @Subkey('ipv6') IShspSocket? socketIpv6,
    IErmesBookService<BookData>? bookService,
    ErmesConnectionsHandler? connectionsHandler,
    this.keyExchange,
    bool? enableEncryption,
    int? connectionTimeoutMs,
    IErmesSignalLastSeenStore? signalLastSeenStore,
    OrcSymmetricNatDetector? natDetector,
    OrcSignalRepublishSettings? republishSettings,
    String? registryKey,
  }) : signalLastSeen = signalLastSeenStore ?? ErmesSignalLastSeenStore(),
       sockets = OrcFamilySockets(ipv4: socket, ipv6: socketIpv6),
       bookService = bookService ?? ErmesBookService(),
       connectionsHandler =
           connectionsHandler ?? ErmesConnectionsHandlerFactory.createHandler(),
       _enableEncryption = enableEncryption ?? true,
       _connectionTimeoutMs = connectionTimeoutMs ?? defaultConnectionTimeoutMs,
       _natDetector = natDetector ?? OrcSymmetricNatDetector(),
       republishSettings =
           republishSettings ?? const OrcSignalRepublishSettings(),
       _registryKey = registryKey ?? 'default';

  /// Registry lookups live in `orc_ermes_registry.dart` (hand-maintained).
  factory OrcErmes.dependencyInjectionFactory({
    String key = 'default',
    // ignore: avoid_unused_constructor_parameters
    String subkey = 'default',
  }) => _orcErmesFromRegistry(key);

  @override
  @protected
  final IErmesSignalingServer signalingServer;
  @override
  @protected
  final IErmesSignalingHandler<ShspPeer> signalingHandler;

  /// SHSP sockets by address family; each Connection dials over its own.
  @protected
  final OrcFamilySockets sockets;
  @override
  @protected
  final IErmesBookService<BookData> bookService;
  @override
  @protected
  final ErmesConnectionsHandler connectionsHandler;

  /// This peer's key pair, forwarded to every [OrcConnectionOpener] so the
  /// per-peer shared secrets can be derived. Required when encryption is on.
  @override
  @protected
  final IKeyExchange? keyExchange;
  final bool _enableEncryption;

  /// Newest accepted signal per counterpart, shared by every opener.
  @override
  @protected
  final IErmesSignalLastSeenStore signalLastSeen;
  final int _connectionTimeoutMs;
  final OrcSymmetricNatDetector _natDetector;
  @override
  @protected
  final OrcSignalRepublishSettings republishSettings;
  final String _registryKey;

  @override
  @protected
  final Map<IdPeer, ErmesPeerConnections> connections = {};

  @override
  @protected
  String get registryKey => _registryKey;

  /// One applier for the orchestrator's lifetime: it remembers the last
  /// signal-derived key per peer, so a re-dial in a later [openConnection]
  /// still retires the superseded encryption key.
  @override
  @protected
  late final OrcSignalCipherApplier? cipherApplier = switch (keyExchange) {
    final k? => OrcSignalCipherApplier(k),
    null => null,
  };

  @override
  @protected
  bool get encryptionEnabled => _enableEncryption;

  @override
  @protected
  OrcConnectionOpener newConnectionOpener() => OrcConnectionOpener(
    signalingServer: signalingServer,
    signalingHandler: signalingHandler,
    sockets: sockets,
    bookService: bookService,
    enableEncryption: _enableEncryption,
    connectionTimeoutMs: _connectionTimeoutMs,
    keyExchange: keyExchange,
    cipherApplier: cipherApplier,
    lastSeen: signalLastSeen,
    natDetector: _natDetector,
  );
}
