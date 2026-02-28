import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../iermes.dart';

/// Interface for managing an Ermes connection
///
/// This interface provides methods for managing a peer-to-peer connection,
/// including reconnection, state management, and connection lifecycle.
abstract class IErmesConnection {
  /// Connect to the other peer
  ///
  /// Returns a new [IErmesRepository] instance for the reconnected connection
  Future<IErmesRepository> connect();

  /// Get the ID of this connection
  ///
  /// Returns the peer identifier for this connection
  IdPeer getIdConnection();

  /// Get the underlying repository instance
  ///
  /// Returns the [IErmesRepository] used by this connection
  IErmesRepository getIErmesRepository();

  /// Destroy the connection
  ///
  /// [close] If true, close the connection before destroying. Default is true.
  Future<void> destroyConnection({bool close = true});
}
