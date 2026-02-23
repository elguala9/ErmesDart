import 'dart:async';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import 'ermes_storage_and_caching.dart';

/// Storage and caching system with message deletion capabilities
@includeInBarrelFile
class ErmesStorageAndCachingMessages<DataJson extends MessageType>
    extends ErmesStorageAndCaching<DataJson>
    implements IErmesStorageAndCachingMessages<DataJson> {
  ErmesStorageAndCachingMessages(
    super.storageService,
    super.cachingService, {
    super.maxNumberOfElementCached,
    super.cachingMode,
  });

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
