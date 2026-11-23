import 'package:iermes/iermes.dart';

import 'ermes_peer.dart';
import 'ermes_peer_connections.dart';

/// Parameters of [ErmesPeerConnectionsFactory.create].
class ErmesPeerConnectionsInput {
  /// Creates the input: the [peer] and the Connections already established.
  const ErmesPeerConnectionsInput({
    required this.peer,
    this.connections = const {},
  });

  /// Remote peer the Connections belong to.
  final IdAccountType peer;

  /// Connections already established, by address family.
  final Map<ErmesConnectionContext, ErmesPeer> connections;
}

/// Factory for [ErmesPeerConnections].
class ErmesPeerConnectionsFactory {
  /// Private constructor to prevent instantiation.
  ErmesPeerConnectionsFactory._();

  /// Builds the aggregate from [input].
  static ErmesPeerConnections create(ErmesPeerConnectionsInput input) {
    final aggregate = ErmesPeerConnections(input.peer);
    input.connections.forEach(aggregate.add);
    return aggregate;
  }
}
