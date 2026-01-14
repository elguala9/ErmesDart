// Test file for ErmesStorageAndCaching concrete implementation
// Tests the interface contract using testStorageAndCaching from ermes_test

import 'package:ermes_storage/ermes_storage.dart';
import 'package:ermes_test/ermes_test.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:work_db/work_db.dart';

void main() async {
  final db = WorkDbFactory.createMemory();

  testStorageAndCaching<MessageType>(
    'ErmesStorageAndCaching',
    (storage, caching, maxCached, mode) => ErmesStorageAndCaching<MessageType>(
      storage,
      caching,
      maxNumberOfElementCached: maxCached,
      cachingMode: mode,
    ),
    ErmesStorageRepository<MessageType>(db, 'test_messages'),
    ErmesCachingService<MessageType>(ErmesCachingRepository<MessageType>(100)),
  );
}
