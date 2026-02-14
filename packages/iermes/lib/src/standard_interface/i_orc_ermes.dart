import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

/// Orchestrator interface for managing multiple Ermes connections
///
/// This high-level interface provides a simplified API for managing
/// multiple peer connections, handling message routing, and connection
/// lifecycle.
@includeInBarrelFile
abstract class IOrcErmes {
  /// Send data to a specific peer
  ///
  /// [data] The data to send
  /// [peer] The ID of the peer to send data to
  Future<void> send(TypeOfDataExternal data, IdPeer peer);

  /// Register a callback for receiving messages from any peer
  ///
  /// [callbackOnData] Callback that receives the data and the sender's peer ID
  Future<void> onMessage(CallbackOnDataArrivedFrom callbackOnData);

  /// Open a connection to a peer
  ///
  /// [peer] The ID of the peer to connect to
  Future<void> openConnection(IdPeer peer);

  /// Close a connection to a peer
  ///
  /// [peer] The ID of the peer to disconnect from
  Future<void> closeConnection(IdPeer peer);

  /// Destroy the orchestrator and all its connections
  ///
  /// [force] If true, force immediate destruction without flushing
  Future<void> destroy({bool force = false});

  /// Save the state of all connections
  Future<void> save();

  /// Get a list of all connected peer IDs
  ///
  /// Returns a future that resolves to a peer ID (Note: This seems to be a bug
  /// in the TS version, should probably return List<IdPeer>)
  Future<IdPeer> getConnections();
}
