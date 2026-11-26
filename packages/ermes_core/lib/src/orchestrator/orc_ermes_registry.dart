part of 'orc_ermes.dart';

/// Resolves every [OrcErmes] dependency from the registry under [key].
///
/// Hand-maintained stand-in for the generated DI factory body: required
/// parameters use `getInstance`, nullable ones `tryGetInstance`.
OrcErmes _orcErmesFromRegistry(String key) {
  final r = RegistryManager.instance;
  return OrcErmes(
    signalingServer: r.getInstance<IErmesSignalingServer>(key: key),
    signalingHandler: r.getInstance<IErmesSignalingHandler<ShspPeer>>(key: key),
    socket: r.tryGetInstance<IShspSocket>(key: key, subkey: 'ipv4'),
    socketIpv6: r.tryGetInstance<IShspSocket>(key: key, subkey: 'ipv6'),
    bookService: r.tryGetInstance<IErmesBookService<BookData>>(key: key),
    connectionsHandler: r.tryGetInstance<ErmesConnectionsHandler>(key: key),
    keyExchange: r.tryGetInstance<IKeyExchange>(key: key),
    enableEncryption: r.tryGetInstance<bool>(key: key),
    connectionTimeoutMs: r.tryGetInstance<int>(key: key),
    signalLastSeenStore: r.tryGetInstance<IErmesSignalLastSeenStore>(key: key),
    natDetector: r.tryGetInstance<OrcSymmetricNatDetector>(key: key),
    republishSettings: r.tryGetInstance<OrcSignalRepublishSettings>(key: key),
    // registryKey is the literal DI key this factory was invoked with, not
    // a registry lookup.
    registryKey: key,
  );
}
