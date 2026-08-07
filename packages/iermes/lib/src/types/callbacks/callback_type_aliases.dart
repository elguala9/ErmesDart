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



import '../common/type_aliases.dart';

// ============================================================================
// SIMPLE TYPE ALIASES (no dependencies)
// ============================================================================

/// Callback type for connection close events
typedef CloseCallback = void Function();

/// Callback type for requesting missing message IDs
typedef CallbackIdsToRequest = Future<void> Function(List<IdType> ids);

/// Callback type for generic signal reception
typedef OnSignalCallback<SignalMessageType> =
    void Function(SignalMessageType input);

// ============================================================================
// CLASSES AND TYPEDEFS WITH FORWARD REFERENCES
// ============================================================================

/// Data transfer object for socket information
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
typedef SocketReadyCallback<SocketType> =
    void Function(SocketDto<SocketType> socket);

/// Callback invoked when the ECDH key exchange is completed
typedef CallbackOnKeyExchangeCompleted = void Function(IdAccountType peerId);
