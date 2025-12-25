import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

import '../ermes_connection.dart';

/// 6️⃣ Factory per ErmesConnection
/// Tradotto da: ErmesConnectionFactory.ts
class ErmesConnectionFactory {
  static ErmesConnection createConnection(
    IErmesSignalingHandler<dynamic> signalingHandler,
    IErmesFactory<dynamic> factory,
    IErmesRepository repository,
    IdPeer connectionId,
  ) =>
      ErmesConnection(
        signalingHandler,
        factory,
        repository,
        connectionId,
      );
}
