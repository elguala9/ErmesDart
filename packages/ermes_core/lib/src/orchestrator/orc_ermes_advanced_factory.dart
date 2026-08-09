
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

  /// Creates an [OrcErmes] from already-built signaling, handler, and socket
  /// components, optionally attaching a book service.
  static Future<OrcErmes> create({
    required IErmesSignalingServer signalingServer,
    required IErmesSignalingHandler<ShspPeer> signalingHandler,
    required IShspSocket socket,
    IErmesBookService<BookData>? bookService,
    IKeyExchange? keyExchange,
    bool enableEncryption = true,
    int connectionTimeoutMs = defaultConnectionTimeoutMs,
  }) async => OrcErmes(
      signalingServer: signalingServer,
      signalingHandler: signalingHandler,
      socket: socket,
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
      overridePort: overridePort,
    );

    return OrcErmes(
      signalingServer: signalingServer,
      signalingHandler: signalingHandler,
      socket: handler,
      bookService: bookService,
      keyExchange: keyExchange,
      enableEncryption: enableEncryption,
      connectionTimeoutMs: connectionTimeoutMs,
    );
  }
}
