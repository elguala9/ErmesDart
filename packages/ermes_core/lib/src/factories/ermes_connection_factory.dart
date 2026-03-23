
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../ermes_connection.dart';

/// 6️⃣ Factory per ErmesConnection
/// Tradotto da: ErmesConnectionFactory.ts

class ErmesConnectionFactory {
  ErmesConnectionFactory._();

  
  static ErmesConnection createConnection(
    IErmesSignalingHandler<IShspSocket> signalingHandler,
    IErmesRepository repository,
    IdPeer connectionId,
  ) => ErmesConnection(signalingHandler, repository, connectionId);
}
