

import '../../iermes.dart';

/// Private interface for ID handler storage operations
abstract class _IIdHandlerStoragePrivate {
  /// Update the stored ID
  ///
  /// [id] The new ID value to store
  Future<void> update(IdType id);

  /// Save the current ID to permanent storage
  void save();

  /// Close the storage connection
  void close();

  /// Destroy the storage and free all resources
  void destroy();
}

/// Repository interface for ID handler storage
///
/// This interface provides persistent storage for ID counters in the
/// repository layer.
abstract class IIdHandlerStorageRepository
    implements _IIdHandlerStoragePrivate {}

/// Service interface for ID handler storage
///
/// This interface provides persistent storage for ID counters in the service
/// layer.
abstract class IIdHandlerStorageService implements _IIdHandlerStoragePrivate {}
