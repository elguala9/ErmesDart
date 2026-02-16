import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../iermes.dart';

/// Private interface for message control operations
abstract class _IErmesMessageControlPrivate {
  /// Store an ID that has arrived
  ///
  /// [id] The message ID that was received
  void idArrived(IdType id);

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
}

/// Repository interface for message control
///
/// This interface handles tracking of message IDs to detect gaps in the
/// message sequence and request retransmission of missing messages.
@includeInBarrelFile
abstract class IErmesMessageControlRepository
    implements _IErmesMessageControlPrivate {
  /// Save the current state to persistent storage
  Future<void> saveState();
}

/// Service interface for message control
///
/// This interface provides the same message tracking functionality
/// as the repository but for the service layer.
@includeInBarrelFile
abstract class IErmesMessageControlService
    implements _IErmesMessageControlPrivate {}
