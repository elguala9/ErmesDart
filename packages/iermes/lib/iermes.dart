/// Interfaces and abstract classes for the Ermes messaging system.
///
/// This library provides all the interface definitions for implementing
/// the Ermes protocol, including:
/// - Standard interfaces for Ermes communication
/// - Signaling interfaces for peer connections
/// - Storage interfaces for message persistence
/// - Input/configuration types
library iermes;

// Signaling interfaces
export 'src/signaling_interface/i_ermes_book.dart';
export 'src/signaling_interface/i_ermes_signaling.dart';
export 'src/signaling_interface/i_ermes_signaling_factory.dart';
export 'src/signaling_interface/i_ermes_signaling_handler.dart';
export 'src/signaling_interface/i_ermes_signaling_server.dart';
// Standard interfaces
export 'src/standard_interface/i_ermes.dart';
export 'src/standard_interface/i_ermes_connection.dart';
export 'src/standard_interface/i_ermes_connections_handler.dart';
export 'src/standard_interface/i_ermes_factory.dart';
export 'src/standard_interface/i_ermes_ice.dart';
export 'src/standard_interface/i_ermes_message_control.dart';
export 'src/standard_interface/i_id_handler.dart';
export 'src/standard_interface/i_id_handler_factory.dart';
export 'src/standard_interface/i_id_handler_storage.dart';
export 'src/standard_interface/i_orc_ermes.dart';
// Storage interfaces
export 'src/storage_interface/i_ermes_caching.dart';
export 'src/storage_interface/i_ermes_storage.dart';
export 'src/storage_interface/i_ermes_storage_and_caching.dart';
export 'src/storage_interface/i_ermes_storage_reserved.dart';
// Input types
export 'src/types/ermes_input.dart';
export 'src/types/id_handler_input.dart';
