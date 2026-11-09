import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';

import '../peer_connection/ermes_peer_factory.dart';
import '../service/ermes_service_versioning.dart';
import 'orc_ermes_connection_opener.dart';

/// Builds the [ErmesPeerConfig] an [OrcConnectionOpener] dials with.
extension OrcOpenerPeerConfig on OrcConnectionOpener {
  /// Peer configuration toward [peer] from this opener's settings.
  ErmesPeerConfig peerConfigFor(IdPeer peer) => ErmesPeerConfig(
        remotePeerId: peer,
        socket: socket,
        signalingHandler: signalingHandler,
        ermesBookService: bookService,
        idHandler: IdHandlerServiceFactory.createDefault(),
        timeoutMs: connectionTimeoutMs,
        enableEncryption: enableEncryption,
        versionNegotiation: const ErmesVersionNegotiationOptions(),
      );
}
