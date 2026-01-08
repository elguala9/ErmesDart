/// 7️⃣ Factory per ErmesConnectionsHandler
/// Tradotto da: ErmesConnectionsHandlerFactory.ts
library ermes_connections_handler_factory;

import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../ermes_connections_handler.dart';

@includeInBarrelFile
class ErmesConnectionsHandlerFactory {
  @includeInBarrelFile
  static ErmesConnectionsHandler createHandler() => ErmesConnectionsHandler();
}
