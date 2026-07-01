import 'dart:async';


import 'package:iermes/iermes.dart';

import 'ermes_storage_and_caching.dart';

/// Storage and caching system with message deletion capabilities

class ErmesStorageAndCachingMessages<DataJson extends StorageType>
    extends ErmesStorageAndCaching<DataJson>
    implements IErmesStorageAndCachingMessages<DataJson> {
  /// Creates the message-oriented storage/caching layer with the given
  /// services and cache configuration.
  ErmesStorageAndCachingMessages(
    super.storageService,
    super.cachingService, {
    super.maxNumberOfElementCached,
    super.cachingMode,
  });

  /// Deletes every message with an ID from 0 up to and including [id].
  @override
  void deleteUntil(int id) {
    // Delete all IDs from 0 to the passed id (inclusive)
    for (var i = 0; i <= id; i++) {
      // Delete from both cache and storage without awaiting
      unawaited(caching.delete(i));
      unawaited(storage.delete(i));
    }
  }
}
