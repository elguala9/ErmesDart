import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';

import '../standard_interface/i_ermes.dart';
import '../standard_interface/i_ermes_message_control.dart';
import '../standard_interface/i_id_handler.dart';
import '../storage_interface/i_ermes_storage_and_caching.dart';

/// Generic configuration input for Ermes service
@includeInBarrelFile
class ErmesServiceInputGeneric<RepoType> {
  /// Creates service input configuration
  const ErmesServiceInputGeneric({
    required this.repository,
    required this.idHandler,
    this.callbackOnDataArrived,
    this.maxByte,
    this.maxBuffer,
    this.ermesStorageAndCaching,
    this.ermesMessageControlService,
    this.missingMessagesCheckIntervalMs,
    this.missingMessagesThreshold,
  });

  /// The repository to use for data transmission
  final RepoType repository;

  /// Callback for when data arrives
  final CallbackOnDataArrived? callbackOnDataArrived;

  /// ID handler for generating message IDs
  final IIdHandlerService idHandler;

  /// Maximum bytes per message chunk
  final int? maxByte;

  /// Maximum buffer size
  final int? maxBuffer;

  /// Optional storage and caching implementation
  final IErmesStorageAndCaching<MessageType>? ermesStorageAndCaching;

  /// Optional message control service for tracking missing messages
  final IErmesMessageControlService? ermesMessageControlService;

  /// Interval in milliseconds for checking missing messages
  final int? missingMessagesCheckIntervalMs;

  /// Threshold for considering messages as missing
  final int? missingMessagesThreshold;
}

/// Standard configuration input for Ermes service
@includeInBarrelFile
typedef ErmesServiceInput = ErmesServiceInputGeneric<IErmesRepository>;

/// Configuration for peer repository
@includeInBarrelFile
@deprecated
class ErmesPeerRepositoryInput {
  /// Creates peer repository input configuration
  const ErmesPeerRepositoryInput({this.offer, this.iceServers});

  /// Optional initial offer signal
  final Signal? offer;

  /// ICE servers configuration for STUN/TURN
  final List<Map<String, dynamic>>? iceServers;
}
