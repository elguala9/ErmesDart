import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

import '../ermes_connection.dart';

/// 6️⃣ Factory per ErmesConnection
/// Tradotto da: ErmesConnectionFactory.ts
@includeInBarrelFile
class ErmesConnectionFactory {
  @includeInBarrelFile
  static ErmesConnection createConnection(
    IErmesSignalingHandler<dynamic> signalingHandler,
    IErmesFactory<dynamic> factory,
    IErmesRepository repository,
    IdPeer connectionId,
  ) => ErmesConnection(signalingHandler, factory, repository, connectionId);
}
