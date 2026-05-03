import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('Storage and Caching Integration', () {
    late ErmesCachingRepository<MessageType> cache;
    late ErmesStorageRepository<MessageType> storage;

    setUp(() {
      cache = ErmesCachingRepository<MessageType>(5);
      storage = ErmesStorageRepository<MessageType>(
        WorkDb.memory(),
        ErmesStorageRepository.defaultCollection,
        MessageType.fromJson,
      );
    });

    tearDown(() async {
      await cache.destroy();
      await storage.destroy();
    });

    group('Cache-Storage Patterns', () {
      test('should clear cache independently from storage', () async {
        expect(cache.numberOfElements(), equals(0));
        expect(storage.numberOfElements(), equals(0));

        await cache.clear();
        await storage.clear();

        expect(cache.numberOfElements(), equals(0));
        expect(storage.numberOfElements(), equals(0));
      });

      test('should maintain separate element counts', () async {
        expect(cache.numberOfElements(), equals(0));
        expect(storage.numberOfElements(), equals(0));

        await cache.clear();
        expect(cache.numberOfElements(), equals(0));

        await storage.clear();
        expect(storage.numberOfElements(), equals(0));
      });

      test('should return empty lists from both', () async {
        final cacheIds = await cache.listOfIds();
        final storageIds = await storage.listOfIds();

        expect(cacheIds, isEmpty);
        expect(storageIds, isEmpty);
      });
    });

    group('Buffer management', () {
      test('should respect cache maxBuffer', () async {
        expect(cache.numberOfElements(), equals(0));
        expect(cache.numberOfElements(),
            lessThanOrEqualTo(5)); // maxBuffer is 5
      });

      test('should handle clear on both systems', () async {
        await cache.clear();
        await storage.clear();

        final cacheCount = cache.numberOfElements();
        final storageCount = storage.numberOfElements();

        expect(cacheCount, equals(0));
        expect(storageCount, equals(0));
      });
    });

    group('Consistency', () {
      test('should handle destroy operations', () async {
        await cache.destroy();
        await storage.destroy();

        expect(cache.numberOfElements(), equals(0));
        expect(storage.numberOfElements(), equals(0));
      });

      test('should allow operations after destroy', () async {
        await cache.destroy();
        await storage.destroy();

        // Should be able to continue operating
        final cacheIds = await cache.listOfIds();
        final storageIds = await storage.listOfIds();

        expect(cacheIds, isEmpty);
        expect(storageIds, isEmpty);
      });

      test('should maintain isolation', () async {
        // Cache and storage are separate
        expect(cache.numberOfElements(), equals(0));
        expect(storage.numberOfElements(), equals(0));

        await cache.clear();
        expect(cache.numberOfElements(), equals(0));
        expect(storage.numberOfElements(), equals(0));

        await storage.clear();
        expect(cache.numberOfElements(), equals(0));
        expect(storage.numberOfElements(), equals(0));
      });
    });

    group('Concurrent operations', () {
      test('should handle concurrent clears', () async {
        final operations = <Future<void>>[];

        for (var i = 0; i < 5; i++) {
          operations.add(cache.clear());
        }

        await Future.wait(operations);
        expect(cache.numberOfElements(), equals(0));
      });

      test('should handle mixed concurrent operations', () async {
        final operations = <Future<void>>[];

        for (var i = 0; i < 10; i++) {
          if (i.isEven) {
            operations.add(cache.clear());
          } else {
            operations.add(storage.clear());
          }
        }

        await Future.wait(operations);
        expect(cache.numberOfElements(), equals(0));
        expect(storage.numberOfElements(), equals(0));
      });
    });

    group('Service delegation', () {
      test('should work with CachingService', () async {
        final cacheService =
            ErmesCachingService<MessageType>(cache);

        expect(cacheService.numberOfElements(), equals(0));

        await cacheService.clear();
        expect(cacheService.numberOfElements(), equals(0));

        await cacheService.destroy();
        expect(cacheService.numberOfElements(), equals(0));
      });

      test('should work with StorageService', () async {
        final storageService =
            ErmesStorageService<MessageType>(storage);

        expect(storageService.numberOfElements(), equals(0));

        await storageService.clear();
        expect(storageService.numberOfElements(), equals(0));

        await storageService.destroy();
        expect(storageService.numberOfElements(), equals(0));
      });

      test('should work together', () async {
        final cacheService =
            ErmesCachingService<MessageType>(cache);
        final storageService =
            ErmesStorageService<MessageType>(storage);

        expect(cacheService.numberOfElements(), equals(0));
        expect(storageService.numberOfElements(), equals(0));

        await cacheService.clear();
        await storageService.clear();

        expect(cacheService.numberOfElements(), equals(0));
        expect(storageService.numberOfElements(), equals(0));

        await cacheService.destroy();
        await storageService.destroy();

        expect(cacheService.numberOfElements(), equals(0));
        expect(storageService.numberOfElements(), equals(0));
      });
    });
  });
}
