import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../iermes.dart';

/// High-level facade for peer-to-peer messaging
///
/// This interface provides simplified access to the Ermes messaging system,
/// aggregating connection management, message sending/receiving, ECDH key
/// exchange, and offline queueing into a single coherent API.
@includeInBarrelFile
abstract class IErmesPeer {
  /// The ID of the remote peer
  IdAccountType get remotePeerId;

  // ========================================================================
  // Lifecycle
  // ========================================================================


  /// Dispose of the peer connection
  ///
  /// [flushBeforeClose] If true (default), flushes the offline queue before
  /// closing the connection
  Future<void> dispose({bool flushBeforeClose = true});

  // ========================================================================
  // Messaging - send queues offline if disconnected
  // ========================================================================

  /// Send a message to the remote peer
  ///
  /// If the peer is connected, sends immediately. If disconnected, queues
  /// the message to be sent upon reconnection.
  ///
  /// [data] The message data to send
  void send(TypeOfDataExternal data);

  /// Register a listener for incoming messages
  void addOnMessageListener(CallbackOnDataArrived callback);

  /// Remove a specific message listener
  void removeOnMessageListener(CallbackOnDataArrived callback);

  /// Clear all message listeners
  void clearOnMessageListeners();

}
