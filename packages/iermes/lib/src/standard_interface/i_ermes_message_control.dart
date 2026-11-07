

import '../../iermes.dart';

/// Private interface for message control operations
abstract class _IErmesMessageControlPrivate {
  /// Store an ID that has arrived
  ///
  /// [id] The message ID that was received
  void idArrived(IdType id);

  /// Mark an ID as unrecoverable (the peer answered `gone`, RFC section
  /// 10.2) so it is no longer requested. Unknown ids are ignored.
  void idGone(IdType id);

  /// Record the counterpart's own highest sent [id] (`ackCurrentId`, RFC
  /// section 9.2). Every id above the highest contiguous received id up to
  /// [id] that has not arrived is recorded as missing. A value not above the
  /// highest id seen so far is a no-op
  void counterpartCurrentId(IdType id);

  /// Request the IDs of messages that are missing
  ///
  /// Returns a list of message IDs that need to be retransmitted
  Future<List<IdType>> idsToRequest();

  /// Get the number of missing message IDs
  ///
  /// Returns the count of messages that haven't been received
  int numberOfMissingIds();

  /// Set the callback to be called when IDs need to be requested
  ///
  /// [callback] Callback to execute when missing IDs are detected
  void setCallbackIdsToRequest(CallbackIdsToRequest callback);

  /// Clear all stored message tracking data
  Future<void> clear();

  /// Destroy the message control instance and free resources
  Future<void> destroy();

  /// Get the highest contiguous message ID received from the remote peer
  /// (RFC section 9.1): every ID up to it has arrived. 0 when ID 1 is
  /// still missing. Returns null if no message has been received yet
  IdType? getLastReceivedId();
}

/// Repository interface for message control
///
/// This interface handles tracking of message IDs to detect gaps in the
/// message sequence and request retransmission of missing messages.
abstract class IErmesMessageControlRepository
    implements _IErmesMessageControlPrivate {
  /// Save the current state to persistent storage
  Future<void> saveState();
}

/// Service interface for message control
///
/// This interface provides the same message tracking functionality
/// as the repository but for the service layer.
abstract class IErmesMessageControlService
    implements _IErmesMessageControlPrivate {}
