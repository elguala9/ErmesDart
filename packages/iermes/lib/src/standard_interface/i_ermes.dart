import '../../iermes.dart';

export 'i_ermes_service.dart';

/// Base private interface for Ermes connections
abstract class IErmesPrivate {
  /// Returns true if the connection is not usable for traffic - either it was
  /// never opened, or it has since been closed.
  ///
  /// Deliberately NOT called `isClosed`: [IErmesRepository] implementations
  /// extend shsp's `ShspInstance`, which already has an `isClosed` meaning
  /// "close() was called on this peer". The two are different - a repository
  /// that has not completed its handshake yet is unusable but not closed - and
  /// reusing the name made the implementation override shsp's own state, which
  /// then refused to send the handshake that would have opened it.
  bool get isConnectionClosed;
  /// Returns true if the connection is closing
  bool isClosing();
  /// Returns true if the connection is open
  bool isOpen();
}

/// Repository implementation of the Ermes protocol
///
/// This interface defines the low-level repository layer that handles
/// raw data transmission over peer connections.
abstract class IErmesRepository implements IErmesPrivate {
  /// Send data over the peer connection
  ///
  /// [data] The serialized data that will be sent over peer connection
  void send(SerializableDataType data);

  /// Register a listener to be called when data arrives
  ///
  /// [callback] Callback that will be called when the data arrives
  void addOnMessageDataListener(CallbackOnDataRepository callback);

  /// Remove a specific listener for incoming data
  ///
  /// [callback] The callback to remove
  void removeOnMessageDataListener(CallbackOnDataRepository callback);

  /// Clear all listeners for incoming data
  void clearOnMessageDataListeners();

  /// Close the connection with the other peer
  ///
  /// [force] If false (default), flush before closing. If true, close
  /// immediately.
  void destroy({bool force = false});

  IdAccountType get remotePeerId;

  /// Address-family context of this Connection, mixed into the session-key
  /// KDF so each Connection to the same peer has its own key (RFC 8.1).
  ErmesConnectionContext get connectionContext;
}

/// Convenience accessors on [IErmesRepository].
extension IErmesRepositoryCipherKey on IErmesRepository {
  /// Key of this Connection's cipher in the peer cipher handler.
  String get cipherKey => peerCipherKey(remotePeerId, connectionContext);
}
