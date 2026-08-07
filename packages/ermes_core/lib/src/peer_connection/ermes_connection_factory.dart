
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'ermes_connection.dart';

/// 6️⃣ Factory per ErmesConnection
/// Tradotto da: ErmesConnectionFactory.ts

/// Factory for creating [ErmesConnection] instances.
class ErmesConnectionFactory {
  /// Private constructor to prevent instantiation.
  ErmesConnectionFactory._();

  /// Creates a new [ErmesConnection] wiring the given signaling handler,
  /// repository, and connection identifier.
  static ErmesConnection createConnection(
    IErmesSignalingHandler<IShspSocket> signalingHandler,
    IErmesRepository repository,
    IdPeer connectionId,
  ) => ErmesConnection(signalingHandler, repository, connectionId);
}
