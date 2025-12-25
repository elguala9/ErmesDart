import 'i_ermes_signaling.dart';
import 'i_ermes_signaling_server.dart';

/// Callback type for when a socket is ready
typedef SocketReadyCallback<SocketType> = void Function(
  SocketDto<SocketType> socket,
);

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

/// Interface for creating and handling WebRTC peer signaling
///
/// This interface manages the WebRTC handshake process, creating
/// offers and answers, and maintaining peer connections.
abstract class IErmesSignalingHandler<SocketType> {
  /// Create a signaling message (offer/answer) for a peer
  ///
  /// [remotePeerId] Optional peer ID to create a specific signal for
  /// Returns a signal that can be sent to the other peer
  Future<SignalType> createSignal([IdAccountType? remotePeerId]);

  /// Process a signal received from another peer
  ///
  /// [signalString] The signal received from the peer
  /// [from] The account ID of the peer who sent the signal
  Future<void> processSignal(SignalType signalString, IdAccountType from);

  /// Get the socket for a specific peer
  ///
  /// Throws an exception if the socket is not ready
  /// [of] The peer ID to get the socket for
  /// Returns the socket DTO with connection information
  Future<SocketDto<SocketType>> getSocket(IdAccountType of);

  /// Check if a socket is ready for a specific peer
  ///
  /// [of] The peer ID to check
  /// Returns true if the socket is ready to use
  Future<bool> isSocketReady(IdAccountType of);

  /// Register a callback for when a socket becomes ready
  ///
  /// [from] The peer ID to monitor
  /// [callback] Callback to execute when the socket is ready
  Future<void> onSocketReady(
    IdAccountType from,
    SocketReadyCallback<SocketDto<SocketType>> callback,
  );

  /// Clear the connection with a peer to allow reconnection
  ///
  /// This clears references but doesn't destroy objects
  /// [remotePeerId] The peer ID to clear
  Future<void> clearConnection(IdAccountType remotePeerId);

  /// Softly clear the connection, destroying related objects
  ///
  /// [remotePeerId] The peer ID to clear
  Future<void> softClearConnection(IdAccountType remotePeerId);

  /// Get all peer IDs that have had connections
  ///
  /// Returns a list of all peer IDs (including cleared ones if not destroyed)
  Future<List<IdAccountType>> getAllPeerIds();

  /// Wait for a connection to be established with a peer
  ///
  /// [peerId] The peer ID to wait for
  /// [ms] Timeout in milliseconds
  /// Returns the socket DTO when the connection is ready
  /// Throws a timeout exception if the connection isn't established in time
  Future<SocketDto<SocketType>> waitForConnect(IdAccountType peerId, int ms);

  /// Destroy the handler and all its connections
  Future<void> destroy();
}
