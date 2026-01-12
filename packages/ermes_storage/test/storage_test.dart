import 'package:ermes_storage/ermes_storage.dart';
import 'package:ermes_test/ermes_test.dart';
import 'package:work_db/work_db.dart';

void main() {
  // Caching Repository Tests
  testCachingRepository<Map<String, dynamic>>(
    'ErmesCachingRepository',
    (fromJson, toJson) => createErmesCachingRepository<Map<String, dynamic>>(),
    (json) => json,
    (data) => data,
  );

  // Storage Repository Tests con WorkDb in-memory
  testStorageRepository<Map<String, dynamic>>(
    'ErmesStorageRepository',
    (fromJson, toJson) {
      final db = WorkDbFactory.createMemory();
      return createErmesStorageRepository<Map<String, dynamic>>(db);
    },
    (json) => json,
    (data) => data,
  );

  // Storage and Caching Tests con WorkDb in-memory
  testStorageAndCaching<Map<String, dynamic>>(
    'ErmesStorageAndCaching',
    (storageService, cachingService, maxCached, mode) =>
        ErmesStorageAndCaching<Map<String, dynamic>>(
          storageService,
          cachingService,
          maxNumberOfElementCached: maxCached,
          cachingMode: mode,
        ),
    createErmesStorageService<Map<String, dynamic>>(
      createErmesStorageRepository<Map<String, dynamic>>(
        WorkDbFactory.createMemory(),
      ),
    ),
    createErmesCachingService<Map<String, dynamic>>(),
    (json) => json,
  );
}
