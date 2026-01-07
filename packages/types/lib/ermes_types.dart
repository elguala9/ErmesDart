/// Type definitions and data structures for the Ermes messaging system.
///
/// This library provides all the core types, enums, and data structures
/// used throughout the Ermes messaging protocol, including:
/// - Message types (base, chunk, service)
/// - Signaling types for peer connections
/// - Pagination utilities
/// - Callback type definitions
library ermes_types;

// Callback type aliases
export 'src/callback_type_aliases.dart';
// Core Ermes types
export 'src/ermes_types.dart';
// Pagination types
export 'src/pagination_types.dart';
// Signaling types
export 'src/signaling_types.dart';
// Type aliases
export 'src/type_aliases.dart';
