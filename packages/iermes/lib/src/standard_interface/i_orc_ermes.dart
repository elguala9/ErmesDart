


import '../../iermes.dart';

/// Orchestrator interface for managing multiple Ermes connections
///
/// This high-level interface provides a simplified API for managing
/// multiple peer connections, handling message routing, and connection
/// lifecycle. It also exposes account book operations so that callers
/// never need to interact with the internal [IErmesBookService] directly.
///
/// [TBookInfo] The type used for account metadata in the book service.
abstract class IOrcErmes<TBookInfo> {
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
  /// so that can be create again in a second moment
  Future<void> save();

  /// Get a list of all connected peer IDs
  ///
  /// Returns a future that resolves to a peer ID
  Future<List<IdPeer>> getConnections();

  /// Register a callback called when a peer disconnects and all
  /// reconnection attempts have been exhausted
  ///
  /// [callback] Receives the peer ID that could not be reconnected
  Future<void> onDisconnect(void Function(IdPeer peer) callback);

  /// refresh the socket and recreate all the object that are needed
  ///
  Future<void> refreshSocket();

  // ========================================================================
  // Book Service Methods
  // ========================================================================

  /// Set an account in the book
  ///
  /// [info] Info on the account
  Future<void> setAccount(AccountInfo<TBookInfo> info);

  /// Update an account in the book
  ///
  /// [account] The account identifier to update
  /// [info] Partial account information to update (only specified fields
  /// are updated)
  Future<void> updateAccount(AccountInfo<TBookInfo> info);

  /// Get account information from the book
  ///
  /// [account] The account identifier to retrieve
  /// Returns the account information stored in the book
  /// Throws if account not found
  Future<AccountInfo<TBookInfo>> getAccount(IdAccountType account);

  /// Get a paginated list of accounts
  ///
  /// [cursor] The account ID from which to start retrieval
  /// (alphabetically ordered)
  /// [limit] Maximum number of accounts to return
  /// Returns a paginated list of account information
  Future<PaginationDto<AccountInfo<TBookInfo>, IdAccountType>> getAccountList(
    IdAccountType cursor,
    int limit,
  );

  /// Delete an account from the book
  ///
  /// [account] The account identifier to delete
  /// Returns true if the account was deleted, false if it didn't exist
  Future<bool> deleteAccount(IdAccountType account);

  /// Clear all accounts from the book
  Future<void> clear();

  /// Get the number of accounts in the book
  ///
  /// Returns the count of stored accounts
  Future<int> numberOfElements();

  /// Get a list of all account IDs
  ///
  /// Returns a list of all stored account identifiers
  Future<List<IdAccountType>> listOfIds();

  /// Get peer information for an account
  ///
  /// [account] The account identifier to retrieve peer info for
  /// Returns the peer information if available, null otherwise
  Future<ErmesPeerInfo?> getPeerInfo(IdAccountType account);

  // ========================================================================
  // Signaling Server Methods
  // ========================================================================

  /// Get the unique identifier of the current user
  ///
  /// Returns the account ID
  Future<IdAccountType> getIdAccount();

  /// Check if connected to the signaling server
  ///
  /// Returns true if the connection is active
  Future<bool> isSignalingConnected();

  /// Publish the singla on the server
  ///
  Future<void> publishSignal();

  /// Register a callback for signaling errors
  ///
  /// [callback] Function to call when a signaling error occurs
  Future<void> onSignalingError(void Function(Object err) callback);

  /// Register a callback for when the signaling connection closes
  ///
  /// [callback] Function to call when the signaling connection closes
  Future<void> onSignalingClose(void Function() callback);
}
