
import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'orc_ermes.dart';

/// Advanced factory for creating OrcErmes instances with pre-configured
/// components and various initialization scenarios.
///
/// stun_shsp 0.4.0 removed `StunShspHandlerSingleton`, so the STUN/SHSP stack
/// is now set up through `initializeStunShsp` and read back out of
/// [RegistryManager] under the `ipv4` subkey, which is the family this factory
/// drives.
class OrcErmesAdvancedFactory {
  /// Private constructor to prevent instantiation.
  OrcErmesAdvancedFactory._();

  /// Registry subkey of the IPv4 half of the dual STUN/SHSP stack.
  static const String _ipv4Subkey = 'ipv4';

  /// Binds the STUN/SHSP stack under [key] if it is not bound yet and returns
  /// the IPv4 handler, which doubles as the IPv4 SHSP socket.
  static Future<IStunShspHandler> _getHandler({
    String key = 'default',
  }) async {
    final registry = RegistryManager.instance;
    final existing = registry.getInstanceNullable<IStunShspHandler>(
      key: key,
      subkey: _ipv4Subkey,
    );
    if (existing != null) {
      return existing;
    }
    await initializeStunShsp(key: key);
    return registry.getInstance<IStunShspHandler>(
      key: key,
      subkey: _ipv4Subkey,
    );
  }

  /// The IPv6 handler bound by [_getHandler]; `null` on a host without IPv6.
  static IStunShspHandler? _ipv6Handler({String key = 'default'}) =>
      RegistryManager.instance.getInstanceNullable<IStunShspHandler>(
        key: key,
        subkey: 'ipv6',
      );

  /// Creates an [OrcErmes] from already-built components.
  static Future<OrcErmes> create({
    required IErmesSignalingServer signalingServer,
    required IErmesSignalingHandler<ShspPeer> signalingHandler,
    IShspSocket? socket,
    IShspSocket? socketIpv6,
    IErmesBookService<BookData>? bookService,
    IKeyExchange? keyExchange,
    bool enableEncryption = true,
    int connectionTimeoutMs = defaultConnectionTimeoutMs,
  }) async => OrcErmes(
      signalingServer: signalingServer,
      signalingHandler: signalingHandler,
      socket: socket,
      socketIpv6: socketIpv6,
      bookService: bookService,
      keyExchange: keyExchange,
      enableEncryption: enableEncryption,
      connectionTimeoutMs: connectionTimeoutMs,
    );

  /// Creates an [OrcErmes] configured for STUN NAT traversal, building the
  /// SHSP socket, book service, and signaling handler from the given
  /// STUN server settings.
  static Future<OrcErmes> createWithStun({
    required IErmesSignalingServer signalingServer,
    required IdAccountType accountId,
    required String stunServer,
    int stunPort = 19302,
    int? localShspPort,
    IKeyExchange? keyExchange,
    bool enableEncryption = true,
    int connectionTimeoutMs = defaultConnectionTimeoutMs,
  }) async {
    final handler = await _getHandler();
    handler.setStunServer(stunServer, stunPort);
    _ipv6Handler()?.setStunServer(stunServer, stunPort);

    return _build(
      signalingServer: signalingServer,
      handler: handler,
      overridePort: localShspPort,
      keyExchange: keyExchange,
      enableEncryption: enableEncryption,
      connectionTimeoutMs: connectionTimeoutMs,
    );
  }

  /// Creates an [OrcErmes] wired for testing against a local STUN server
  /// with a short connection timeout.
  static Future<OrcErmes> createForTesting({
    required IErmesSignalingServer signalingServer,
    required IdAccountType accountId,
    IKeyExchange? keyExchange,
    bool enableEncryption = true,
  }) async {
    final handler = await _getHandler();
    handler.setStunServer('localhost', 19302);
    _ipv6Handler()?.setStunServer('localhost', 19302);

    return _build(
      signalingServer: signalingServer,
      handler: handler,
      keyExchange: keyExchange,
      enableEncryption: enableEncryption,
      connectionTimeoutMs: 5000,
    );
  }

  /// Builds the book service and signaling handler over [handler] — which is
  /// both the STUN handler and the IPv4 SHSP socket — and wires an [OrcErmes].
  static OrcErmes _build({
    required IErmesSignalingServer signalingServer,
    required IStunShspHandler handler,
    required bool enableEncryption,
    required int connectionTimeoutMs,
    IKeyExchange? keyExchange,
    int? overridePort,
  }) {
    final bookService = ErmesBookService();
    final signalingHandler = ErmesSignalingHandler.create(
      handler,
      handler,
      bookService,
      handlerIpv6: _ipv6Handler(),
      shspSocketIpv6: _ipv6Handler(),
      overridePort: overridePort,
    );

    return OrcErmes(
      signalingServer: signalingServer,
      signalingHandler: signalingHandler,
      socket: handler,
      socketIpv6: _ipv6Handler(),
      bookService: bookService,
      keyExchange: keyExchange,
      enableEncryption: enableEncryption,
      connectionTimeoutMs: connectionTimeoutMs,
    );
  }
}
