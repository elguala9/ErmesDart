import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

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
@includeInBarrelFile
abstract class IIdHandlerStorageRepository
    implements _IIdHandlerStoragePrivate {}

/// Service interface for ID handler storage
///
/// This interface provides persistent storage for ID counters in the service
/// layer.
@includeInBarrelFile
abstract class IIdHandlerStorageService implements _IIdHandlerStoragePrivate {}
