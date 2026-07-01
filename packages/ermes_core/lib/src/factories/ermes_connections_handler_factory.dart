/// 7️⃣ Factory per ErmesConnectionsHandler
/// Tradotto da: ErmesConnectionsHandlerFactory.ts
library ermes_connections_handler_factory;



import '../ermes_connections_handler.dart';


/// Factory for creating [ErmesConnectionsHandler] instances.
class ErmesConnectionsHandlerFactory {
  /// Private constructor to prevent instantiation.
  ErmesConnectionsHandlerFactory._();

  /// Creates a new [ErmesConnectionsHandler] instance.
  static ErmesConnectionsHandler createHandler() => ErmesConnectionsHandler();
}
