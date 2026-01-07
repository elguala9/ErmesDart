import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';

/// Reserved interface for storage and caching operations
///
/// This interface provides the base operations for storing and retrieving
/// messages, avoiding code duplication between storage and caching
/// implementations.
@includeInBarrelFile
abstract class IErmesStorageAndCachingReserved<DataJson extends MessageType> {
  /// Store a message
  ///
  /// [data] The message to store
  Future<void> store(DataJson data);

  /// Retrieve a message by its ID
  ///
  /// [id] The message ID to retrieve
  /// Returns the message if found, null otherwise
  Future<DataJson?> retrieve(IdType id);

  /// Delete a message by its ID
  ///
  /// [id] The message ID to delete
  /// Returns true if an element existed and was removed, false otherwise
  Future<bool> delete(IdType id);

  /// Clear all stored messages
  Future<void> clear();

  /// Get the number of stored messages
  ///
  /// Returns the count of messages in storage
  int numberOfElements();

  /// Get a list of all stored message IDs
  ///
  /// Returns a list of all message IDs in storage
  Future<List<IdType>> listOfIds();

  /// Destroy the storage and free all resources
  Future<void> destroy();
}
