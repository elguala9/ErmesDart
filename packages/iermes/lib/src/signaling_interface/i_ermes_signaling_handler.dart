import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../iermes.dart';

/// Interface for creating and handling peer signaling
///
/// This interface manages the peer handshake process, creating signals
@includeInBarrelFile
abstract class IErmesSignalingHandler<SocketType> {
  /// Create a signaling message
  ///
  /// remotePeerId Optional peer ID to create a specific signal for
  /// Returns a signal that can be sent to the other peer
  Future<ISignalErmes> createSignal([IdAccountType? remotePeerId]);

  /// Process a signal received from another peer
  ///
  /// [signal] The signal received from the peer
  /// [from] The account ID of the peer who sent the signal
  Future<void> processSignal(
    ISignalErmes signal,
    IdAccountType from,
    SocketReadyCallback<SocketType> callback,
  );

  /// Register a callback for when a socket becomes ready
  ///
  /// [from] The peer ID to monitor
  /// [callback] Callback to execute when the socket is ready
  Future<void> onSocketReady(
    IdAccountType from,
    SocketReadyCallback<SocketType> callback,
  );

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
  /// Returns a list of all peer IDs (including cleared ones
  /// if not destroyed)
  Future<List<IdAccountType>> getAllPeerIds();

  /// Wait for a connection to be established with a peer
  ///
  /// [peerId] The peer ID to wait for
  /// [ms] Timeout in milliseconds
  /// Returns the socket DTO when the connection is ready
  /// Throws a timeout exception if the connection isn't
  /// established in time
  Future<SocketDto<SocketType>> waitForConnect(
    IdAccountType peerId,
    int ms,
  );

  /// Destroy the handler and all its connections
  Future<void> destroy();
}
