import 'package:iermes/iermes.dart';

import '../peer_connection/ermes_peer.dart';
import '../support/exceptions.dart';
import 'orc_ermes_connections.dart';

/// Read access to a single address-family Connection held by the
/// orchestrator (RFC section 2: one Connection per family).
mixin OrcErmesFamilyAccess on OrcErmesConnections {
  /// Connection to [peer] over [family]; throws [CoreException] when no
  /// Connection to [peer], or none over [family], is held.
  ErmesPeer connectionOver(IdPeer peer, ErmesConnectionContext family) {
    final held = connections[peer];
    if (held == null) {
      throw CoreException('No connection to peer $peer');
    }
    return held.connectionOf(family);
  }
}
