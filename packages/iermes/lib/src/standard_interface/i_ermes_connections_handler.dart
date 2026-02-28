import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../iermes.dart';

/// Interface for managing multiple Ermes connections
///
/// This interface provides methods for adding, removing, and retrieving
/// connections in a multi-peer environment.
abstract class IErmesConnectionsHandler {
  /// Add a connection to the handler
  ///
  /// [connection] The connection to add
  void addConnection(IErmesConnection connection);

  /// Delete a connection from the handler
  ///
  /// [connection] The connection to delete
  /// [close] If true, close the connection before deleting. Default is true.
  void deleteConnection(IErmesConnection connection, {bool close = true});

  /// Get a connection by its ID
  ///
  /// [id] The peer ID of the connection to retrieve
  /// Returns the connection associated with the given ID
  IErmesConnection getConnection(IdPeer id);

  /// Save the state of all connections
  Future<void> saveState();

  /// Load previously saved connection states
  Future<void> loadState();
}
