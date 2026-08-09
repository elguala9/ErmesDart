
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'orc_ermes.dart';

/// Factory for creating [OrcErmes] orchestrator instances from
/// pre-built signaling, socket, and book service components.
class OrcErmesFactory {
  /// Private constructor to prevent instantiation.
  OrcErmesFactory._();

  /// Creates an [OrcErmes] orchestrator with the supplied signaling server,
  /// signaling handler, socket, and optional book service.
  static OrcErmes create({
    required IErmesSignalingServer signalingServer,
    required IErmesSignalingHandler<ShspPeer> signalingHandler,
    required IShspSocket socket,
    IErmesBookService<BookData>? bookService,
    bool enableEncryption = true,
    int connectionTimeoutMs = 30000,
  }) =>
      OrcErmes(
        signalingServer: signalingServer,
        signalingHandler: signalingHandler,
        socket: socket,
        bookService: bookService,
        enableEncryption: enableEncryption,
        connectionTimeoutMs: connectionTimeoutMs,
      );
}
