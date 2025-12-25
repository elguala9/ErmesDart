import 'package:ermes_types/ermes_types.dart';

import 'i_ermes.dart';

/// Callback type for connection close events
typedef CloseCallback = void Function();

/// Interface for managing an Ermes connection
///
/// This interface provides methods for managing a peer-to-peer connection,
/// including reconnection, state management, and connection lifecycle.
abstract class IErmesConnection {
  /// Try to reconnect with the other peer
  ///
  /// Returns a new [IErmesRepository] instance for the reconnected connection
  Future<IErmesRepository> reconnect();

  /// Close the connection
  Future<void> close();

  /// Set the callback to be called when the connection is closing
  ///
  /// [callback] The callback to execute on close
  void setCloseCallback(CloseCallback callback);

  /// Check if the connection is closed
  ///
  /// Returns true if the connection is closed
  Future<bool> isClosed();

  /// Ping the other peer to check if it's responding
  ///
  /// Returns true if the other peer responded
  Future<bool> ping();

  /// Get the ID of this connection
  ///
  /// Returns the peer identifier for this connection
  IdPeer getIdConnection();

  /// Get the underlying repository instance
  ///
  /// Returns the [IErmesRepository] used by this connection
  IErmesRepository getIErmesRepository();

  /// Save the current state of the connection
  Future<void> saveState();

  /// Load a previously saved state
  Future<void> loadState();

  /// Destroy the connection
  ///
  /// [close] If true, close the connection before destroying. Default is true.
  Future<void> destroyConnection({bool close = true});
}
