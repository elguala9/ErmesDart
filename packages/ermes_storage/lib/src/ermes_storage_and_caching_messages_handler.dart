import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import 'ermes_storage_and_caching_messages.dart';

/// Singleton handler for managing ErmesStorageAndCachingMessages instances
///
/// Maintains a mapping of storage instances keyed by account type and
/// connection type combinations. This ensures a single storage instance
/// per peer connection.
@includeInBarrelFile
class ErmesStorageAndCachingMessagesHandler {
  ErmesStorageAndCachingMessagesHandler._();

  static final ErmesStorageAndCachingMessagesHandler _instance =
      ErmesStorageAndCachingMessagesHandler._();

  static ErmesStorageAndCachingMessagesHandler get instance => _instance;

  /// Mapping of storage instances keyed by connection ID only
  final Map<IdConnectionType, ErmesStorageAndCachingMessages<MessageType>>
      _storageInstances = {};

  /// Get or retrieve a storage instance for the given connection
  ErmesStorageAndCachingMessages<MessageType>? get(
    IdConnectionType idConnectionType,
  ) {
    return _storageInstances[idConnectionType];
  }

  /// Register a new storage instance
  void set(
    IdConnectionType idConnectionType,
    ErmesStorageAndCachingMessages<MessageType> storage,
  ) {
    _storageInstances[idConnectionType] = storage;
  }

  /// Check if a storage instance exists for the given connection
  bool contains(IdConnectionType idConnectionType) {
    return _storageInstances.containsKey(idConnectionType);
  }

  /// Remove a storage instance
  void remove(IdConnectionType idConnectionType) {
    _storageInstances.remove(idConnectionType);
  }

  /// Get all storage instances
  Map<IdConnectionType, ErmesStorageAndCachingMessages<MessageType>> getAll() =>
      Map.unmodifiable(_storageInstances);

  /// Clear all storage instances
  void clear() {
    _storageInstances.clear();
  }

  /// Get the count of storage instances
  int get count => _storageInstances.length;
}
