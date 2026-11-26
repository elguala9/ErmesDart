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
    with
        OrcErmesCallbacks,
        OrcErmesPassthrough,
        OrcErmesConnections,
        OrcErmesFamilyAccess,
        OrcErmesMaintenance,
        OrcErmesKeyRotation,
        OrcErmesSignalRepublish
    implements IOrcErmes<BookData> {
  /// Creates an orchestrator over the given signaling stack and socket.
  ///
  /// Sockets are resolved per family (`ipv4` / `ipv6` subkeys); each is
  /// optional but at least one is required. One independent Connection is
  /// opened per family available on both peers.
  ///
  /// [enableEncryption] and [connectionTimeoutMs] are nullable so dependency
  /// injection can leave them unregistered and still get the defaults.
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
       connectionsHandler = connectionsHandler ??
           ErmesConnectionsHandlerFactory.createHandler(),
       _enableEncryption = enableEncryption ?? true,
       _connectionTimeoutMs =
           connectionTimeoutMs ?? defaultConnectionTimeoutMs,
       _natDetector = natDetector ?? OrcSymmetricNatDetector(),
       republishSettings =
           republishSettings ?? const OrcSignalRepublishSettings(),
       _registryKey = registryKey ?? 'default';

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
    final socket = RegistryManager.instance.tryGetInstance<IShspSocket>(
      key: key,
      subkey: 'ipv4',
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final socketIpv6 = RegistryManager.instance.tryGetInstance<IShspSocket>(
      key: key,
      subkey: 'ipv6',
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
    final signalLastSeenStore = RegistryManager.instance
        .tryGetInstance<IErmesSignalLastSeenStore>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final natDetector = RegistryManager.instance
        .tryGetInstance<OrcSymmetricNatDetector>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final republishSettings = RegistryManager.instance
        .tryGetInstance<OrcSignalRepublishSettings>(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND

    // GENERATED CODE - DO NOT MODIFY BY HAND
    return OrcErmes(
      signalingServer: signalingServer,
      signalingHandler: signalingHandler,
      socket: socket, // GENERATED CODE - DO NOT MODIFY BY HAND
      socketIpv6: socketIpv6,
      bookService: bookService, // GENERATED CODE - DO NOT MODIFY BY HAND
      connectionsHandler: connectionsHandler,
      keyExchange: keyExchange, // GENERATED CODE - DO NOT MODIFY BY HAND
      enableEncryption: enableEncryption,
      connectionTimeoutMs: connectionTimeoutMs,
      signalLastSeenStore: signalLastSeenStore,
      natDetector: natDetector, // GENERATED CODE - DO NOT MODIFY BY HAND
      republishSettings: republishSettings,
      // registryKey is the literal DI key this factory was invoked with, not
      // a registry lookup: keep this line after regenerating this factory.
      registryKey: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

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
  late final OrcSignalCipherApplier? cipherApplier =
      switch (keyExchange) {
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
