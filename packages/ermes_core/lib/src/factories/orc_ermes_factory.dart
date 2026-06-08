
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../orc_ermes.dart';

class OrcErmesFactory {
  OrcErmesFactory._();

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
