

import '../../../iermes.dart';

/// Generic configuration input for Ermes service
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
  final IErmesStorageAndCaching<StorageType>? ermesStorageAndCaching;

  /// Optional message control service for tracking missing messages
  final IErmesMessageControlService? ermesMessageControlService;

  /// Interval in milliseconds for checking missing messages
  final int? missingMessagesCheckIntervalMs;

  /// Threshold for considering messages as missing
  final int? missingMessagesThreshold;
}

/// Standard configuration input for Ermes service
typedef ErmesServiceInput = ErmesServiceInputGeneric<IErmesRepository>;
