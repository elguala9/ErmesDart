/// Note: This file contains type aliases and classes that bridge between
/// the types package and the iermes package. To avoid circular dependencies,
/// we use forward declarations and dynamic typing where necessary.
///
/// In your actual code, ensure proper imports:
/// ```dart
/// import 'package:iermes/src/types/callback_type_aliases.dart';
/// import 'package:iermes/iermes.dart';
/// ```
library;

import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import 'type_aliases.dart';

// ============================================================================
// SIMPLE TYPE ALIASES (no dependencies)
// ============================================================================

/// Callback type for connection close events
@includeInBarrelFile
typedef CloseCallback = void Function();

/// Callback type for requesting missing message IDs
@includeInBarrelFile
typedef CallbackIdsToRequest = Future<void> Function(List<IdType> ids);

/// Callback type for generic signal reception
@includeInBarrelFile
typedef OnSignalCallback<SignalMessageType> =
    void Function(SignalMessageType input);

// ============================================================================
// CLASSES AND TYPEDEFS WITH FORWARD REFERENCES
// ============================================================================

/// Data transfer object for socket information
@includeInBarrelFile
class SocketDto<SocketType> {
  /// Creates a socket DTO
  const SocketDto({
    required this.socket,
    required this.connectionId,
    required this.remotePeerId,
  });

  /// The actual socket/peer instance
  final SocketType socket;

  /// Unique identifier for this connection
  final String connectionId;

  /// ID of the remote peer
  final IdAccountType remotePeerId;
}

/// Callback type for when a socket is ready
@includeInBarrelFile
typedef SocketReadyCallback<SocketType> =
    void Function(SocketDto<SocketType> socket);
