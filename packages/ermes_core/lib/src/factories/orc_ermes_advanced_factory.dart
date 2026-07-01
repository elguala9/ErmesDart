
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../orc_ermes.dart';

/// Advanced factory for creating OrcErmes instances with pre-configured
/// components and various initialization scenarios.
///
/// This factory handles the creation of all OrcErmes dependencies using
/// [StunShspHandlerSingleton], which unifies STUN NAT traversal and SHSP
/// socket management into a single handler.
class OrcErmesAdvancedFactory {
  /// Private constructor to prevent instantiation.
  OrcErmesAdvancedFactory._();

  /// Returns the shared [StunShspHandlerSingleton], initializing it on the
  /// given [port] if it has not been initialized yet.
  static Future<StunShspHandlerSingleton> _getHandler({int? port}) async {
    final handler = StunShspHandlerSingleton.instance;
    if (!handler.isInitialized) {
      await handler.initialize(port: port);
    }
    return handler;
  }

  /// Creates an [OrcErmes] from already-built signaling, handler, and socket
  /// components, optionally attaching a book service.
  static Future<OrcErmes> create({
    required IErmesSignalingServer signalingServer,
    required IErmesSignalingHandler<ShspPeer> signalingHandler,
    required IShspSocket socket,
    IErmesBookService<BookData>? bookService,
    bool enableEncryption = true,
    int connectionTimeoutMs = 30000,
  }) async => OrcErmes(
      signalingServer: signalingServer,
      signalingHandler: signalingHandler,
      socket: socket,
      bookService: bookService,
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
    bool enableEncryption = true,
    int connectionTimeoutMs = 30000,
  }) async {
    final handler = await _getHandler(port: localShspPort);
    handler.setStunServer(stunServer, stunPort);

    final socket = handler.ipv4ShspSocket;
    final bookService = ErmesBookService();
    final signalingHandler = ErmesSignalingHandler.create(
      handler,
      socket,
      bookService,
      overridePort: localShspPort,
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

  /// Creates an [OrcErmes] wired for testing against a local STUN server
  /// with a short connection timeout.
  static Future<OrcErmes> createForTesting({
    required IErmesSignalingServer signalingServer,
    required IdAccountType accountId,
    bool enableEncryption = true,
  }) async {
    final handler = await _getHandler();
    handler.setStunServer('localhost', 19302);

    final socket = handler.ipv4ShspSocket;
    final bookService = ErmesBookService();
    final signalingHandler = ErmesSignalingHandler.create(
      handler,
      socket,
      bookService,
    );

    return OrcErmes(
      signalingServer: signalingServer,
      signalingHandler: signalingHandler,
      socket: socket,
      bookService: bookService,
      enableEncryption: enableEncryption,
      connectionTimeoutMs: 5000,
    );
  }
}
