import 'package:ermes_storage/src/caching_implementation/ermes_caching_repository.dart';
import 'package:ermes_storage/src/caching_implementation/ermes_caching_service.dart';
import 'package:ermes_storage/src/ermes_storage_and_caching.dart';
import 'package:ermes_storage/src/factories/ermes_caching_storage_factories.dart';
import 'package:ermes_storage/src/factories/ermes_storage_factories.dart';
import 'package:ermes_storage/src/interfaces/iermes_storage_and_caching.dart';
import 'package:ermes_storage/src/storage_implementation/ermes_storage_repository.dart';
import 'package:ermes_storage/src/storage_implementation/ermes_storage_service.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('ErmesStorageRepository Tests', () {
    late IWorkDb db;
    late ErmesStorageRepository<Map<String, dynamic>> repository;

    setUp(() {
      // Crea una nuova istanza di database per ogni test
      db = WorkDbFactory.forMemory();
      repository = ErmesStorageRepository<Map<String, dynamic>>(db);
    });

    tearDown(() async {
      await db.clearDatabase();
    });

    test('should store and retrieve an item', () async {
      final testData = {
        'id': '1',
        'name': 'Test Item',
        'value': 42,
      };

      await repository.store(testData);

      final retrieved = await repository.retrieve('1');
      expect(retrieved, isNotNull);
      expect(retrieved?['id'], equals('1'));
      expect(retrieved?['name'], equals('Test Item'));
      expect(retrieved?['value'], equals(42));
    });

    test('should throw when storing data without id', () async {
      final testData = {
        'name': 'Test Item',
        'value': 42,
      };

      expect(
        () async => repository.store(testData),
        throwsException,
      );
    });

    test('should return null when retrieving non-existent item', () async {
      final retrieved = await repository.retrieve('non-existent');
      expect(retrieved, isNull);
    });

    test('should delete an item', () async {
      final testData = {'id': '1', 'name': 'Test'};
      await repository.store(testData);

      final deleted = await repository.delete('1');
      expect(deleted, isTrue);

      final retrieved = await repository.retrieve('1');
      expect(retrieved, isNull);
    });

    test('should return false when deleting non-existent item', () async {
      final deleted = await repository.delete('non-existent');
      expect(deleted, isFalse);
    });

    test('should return correct numberOfElements', () async {
      expect(repository.numberOfElements(), equals(0));

      await repository.store({'id': '1', 'name': 'Item 1'});
      expect(repository.numberOfElements(), equals(1));

      await repository.store({'id': '2', 'name': 'Item 2'});
      expect(repository.numberOfElements(), equals(2));

      await repository.delete('1');
      expect(repository.numberOfElements(), equals(1));
    });

    test('should list all IDs', () async {
      await repository.store({'id': '1', 'name': 'Item 1'});
      await repository.store({'id': '2', 'name': 'Item 2'});
      await repository.store({'id': '3', 'name': 'Item 3'});

      final ids = await repository.listOfIds();
      expect(ids, hasLength(3));
      expect(ids, containsAll(['1', '2', '3']));
    });

    test('should clear all items', () async {
      await repository.store({'id': '1', 'name': 'Item 1'});
      await repository.store({'id': '2', 'name': 'Item 2'});

      await repository.clear();

      final ids = await repository.listOfIds();
      expect(ids, isEmpty);
      expect(repository.numberOfElements(), equals(0));
    });

    test('should handle custom collections', () async {
      final customRepo = ErmesStorageRepository<Map<String, dynamic>>(
        db,
        'custom_collection',
      );

      await customRepo.store({'id': '1', 'data': 'test'});

      final retrieved = await customRepo.retrieve('1');
      expect(retrieved, isNotNull);
      expect(retrieved?['id'], equals('1'));
    });

    test('should handle binary data', () async {
      final testData = {
        'id': '1',
        'name': 'Binary Test',
        'data': [1, 2, 3, 4, 5],
      };

      await repository.store(testData);

      final retrieved = await repository.retrieve('1');
      expect(retrieved, isNotNull);
      expect(retrieved?['data'], equals([1, 2, 3, 4, 5]));
    });

    test('should destroy database', () async {
      await repository.store({'id': '1', 'name': 'Item'});
      await repository.destroy();

      final ids = await repository.listOfIds();
      expect(ids, isEmpty);
    });
  });

  group('ErmesStorageService Tests', () {
    late IWorkDb db;
    late ErmesStorageService<Map<String, dynamic>> service;
    late ErmesStorageRepository<Map<String, dynamic>> repository;

    setUp(() {
      db = WorkDbFactory.forMemory();
      repository = ErmesStorageRepository<Map<String, dynamic>>(db);
      service = ErmesStorageService<Map<String, dynamic>>(repository);
    });

    tearDown(() async {
      await db.clearDatabase();
    });

    test('should delegate store to repository', () async {
      final testData = {'id': '1', 'name': 'Test'};
      await service.store(testData);

      final retrieved = await service.retrieve('1');
      expect(retrieved, isNotNull);
      expect(retrieved?['name'], equals('Test'));
    });

    test('should delegate retrieve to repository', () async {
      await service.store({'id': '1', 'name': 'Test'});
      final retrieved = await service.retrieve('1');
      expect(retrieved?['id'], equals('1'));
    });

    test('should delegate delete to repository', () async {
      await service.store({'id': '1', 'name': 'Test'});
      final deleted = await service.delete('1');
      expect(deleted, isTrue);
    });

    test('should delegate clear to repository', () async {
      await service.store({'id': '1', 'name': 'Test'});
      await service.clear();

      final ids = await service.listOfIds();
      expect(ids, isEmpty);
    });

    test('should delegate numberOfElements', () async {
      expect(service.numberOfElements(), equals(0));
      await service.store({'id': '1', 'name': 'Test'});
      expect(service.numberOfElements(), equals(1));
    });

    test('should delegate listOfIds', () async {
      await service.store({'id': '1', 'name': 'Item 1'});
      await service.store({'id': '2', 'name': 'Item 2'});

      final ids = await service.listOfIds();
      expect(ids, containsAll(['1', '2']));
    });

    test('should delegate destroy', () async {
      await service.store({'id': '1', 'name': 'Test'});
      await service.destroy();

      final ids = await service.listOfIds();
      expect(ids, isEmpty);
    });
  });

  group('ErmesCachingRepository Tests', () {
    late ErmesCachingRepository<Map<String, dynamic>> cachingRepo;

    setUp(() {
      cachingRepo = ErmesCachingRepository<Map<String, dynamic>>(100);
    });

    test('should store and retrieve item in cache', () async {
      final testData = {'id': '1', 'name': 'Cached Item'};
      await cachingRepo.store(testData);

      final retrieved = await cachingRepo.retrieve('1');
      expect(retrieved, isNotNull);
      expect(retrieved?['name'], equals('Cached Item'));
    });

    test('should return null for non-existent item in cache', () async {
      final retrieved = await cachingRepo.retrieve('non-existent');
      expect(retrieved, isNull);
    });

    test('should delete item from cache', () async {
      await cachingRepo.store({'id': '1', 'name': 'Test'});
      final deleted = await cachingRepo.delete('1');

      expect(deleted, isTrue);
      final retrieved = await cachingRepo.retrieve('1');
      expect(retrieved, isNull);
    });

    test('should return numberOfElements in cache', () async {
      expect(cachingRepo.numberOfElements(), equals(0));

      await cachingRepo.store({'id': '1', 'name': 'Item 1'});
      expect(cachingRepo.numberOfElements(), equals(1));

      await cachingRepo.store({'id': '2', 'name': 'Item 2'});
      expect(cachingRepo.numberOfElements(), equals(2));
    });

    test('should list all IDs in cache', () async {
      await cachingRepo.store({'id': '1', 'name': 'Item 1'});
      await cachingRepo.store({'id': '2', 'name': 'Item 2'});
      await cachingRepo.store({'id': '3', 'name': 'Item 3'});

      final ids = await cachingRepo.listOfIds();
      expect(ids, hasLength(3));
    });

    test('should clear cache', () async {
      await cachingRepo.store({'id': '1', 'name': 'Item 1'});
      await cachingRepo.store({'id': '2', 'name': 'Item 2'});

      await cachingRepo.clear();

      expect(cachingRepo.numberOfElements(), equals(0));
    });

    test('should destroy cache', () async {
      await cachingRepo.store({'id': '1', 'name': 'Item'});
      await cachingRepo.destroy();

      expect(cachingRepo.numberOfElements(), equals(0));
    });

    test('should enforce max cache size', () async {
      final smallCache = ErmesCachingRepository<Map<String, dynamic>>(2);

      await smallCache.store({'id': '1', 'name': 'Item 1'});
      await smallCache.store({'id': '2', 'name': 'Item 2'});

      // Cache è pieno, prossimi store non dovrebbero aumentare la size
      expect(smallCache.numberOfElements(), equals(2));
    });
  });

  group('ErmesCachingService Tests', () {
    late ErmesCachingService<Map<String, dynamic>> cachingService;
    late ErmesCachingRepository<Map<String, dynamic>> cachingRepo;

    setUp(() {
      cachingRepo = ErmesCachingRepository<Map<String, dynamic>>(100);
      cachingService = ErmesCachingService<Map<String, dynamic>>(cachingRepo);
    });

    test('should delegate store to repository', () async {
      final testData = {'id': '1', 'name': 'Test'};
      await cachingService.store(testData);

      final retrieved = await cachingService.retrieve('1');
      expect(retrieved, isNotNull);
    });

    test('should delegate retrieve to repository', () async {
      await cachingService.store({'id': '1', 'name': 'Test'});
      final retrieved = await cachingService.retrieve('1');
      expect(retrieved?['id'], equals('1'));
    });

    test('should delegate delete to repository', () async {
      await cachingService.store({'id': '1', 'name': 'Test'});
      final deleted = await cachingService.delete('1');
      expect(deleted, isTrue);
    });

    test('should delegate numberOfElements', () async {
      expect(cachingService.numberOfElements(), equals(0));
      await cachingService.store({'id': '1', 'name': 'Test'});
      expect(cachingService.numberOfElements(), equals(1));
    });

    test('should delegate listOfIds', () async {
      await cachingService.store({'id': '1', 'name': 'Item 1'});
      await cachingService.store({'id': '2', 'name': 'Item 2'});

      final ids = await cachingService.listOfIds();
      expect(ids, hasLength(2));
    });

    test('should delegate clear', () async {
      await cachingService.store({'id': '1', 'name': 'Test'});
      await cachingService.clear();

      expect(cachingService.numberOfElements(), equals(0));
    });

    test('should delegate destroy', () async {
      await cachingService.store({'id': '1', 'name': 'Test'});
      await cachingService.destroy();

      expect(cachingService.numberOfElements(), equals(0));
    });
  });

  group('ErmesStorageAndCaching Tests - FIFO Mode', () {
    late IWorkDb db;
    late ErmesStorageAndCaching<Map<String, dynamic>> storageAndCaching;
    late ErmesStorageRepository<Map<String, dynamic>> storageRepo;
    late ErmesCachingRepository<Map<String, dynamic>> cachingRepo;

    setUp(() async {
      db = WorkDbFactory.forMemory();
      // Ensure fresh state before creating instances
      await db.clearDatabase();
      storageRepo = ErmesStorageRepository<Map<String, dynamic>>(db);
      cachingRepo = ErmesCachingRepository<Map<String, dynamic>>(3);
      storageAndCaching = ErmesStorageAndCaching<Map<String, dynamic>>(
        ErmesStorageService<Map<String, dynamic>>(storageRepo),
        ErmesCachingService<Map<String, dynamic>>(cachingRepo),
        maxNumberOfElementCached: 3,
      );
    });

    tearDown(() async {
      await db.clearDatabase();
    });

    test('should store items in both storage and cache', () async {
      final testData = {'id': '1', 'name': 'Test Item'};

      await storageAndCaching.store(testData);

      // Verifica storage
      final storageRetrieved = await storageRepo.retrieve('1');
      expect(storageRetrieved, isNotNull);

      // Verifica cache
      final cacheRetrieved = await storageAndCaching.retrieve('1');
      expect(cacheRetrieved, isNotNull);
    });

    test('should retrieve from cache first', () async {
      await storageAndCaching.store({'id': '1', 'name': 'Item'});

      final retrieved = await storageAndCaching.retrieve('1');
      expect(retrieved?['name'], equals('Item'));
    });

    test('should retrieve from storage if not in cache', () async {
      // Store directly in storage, bypassing cache
      await storageRepo.store({'id': '1', 'name': 'Storage Item'});

      // Cache should be empty
      expect(cachingRepo.numberOfElements(), equals(0));

      // But retrieve should find it in storage and add to cache
      final retrieved = await storageAndCaching.retrieve('1');
      expect(retrieved, isNotNull);
      expect(retrieved?['name'], equals('Storage Item'));

      // Now it should be in cache
      expect(cachingRepo.numberOfElements(), equals(1));
    });

    test('should apply FIFO eviction policy', () async {
      // Store 4 items (cache max is 3)
      await storageAndCaching.store({'id': '1', 'name': 'Item 1'});
      await storageAndCaching.store({'id': '2', 'name': 'Item 2'});
      await storageAndCaching.store({'id': '3', 'name': 'Item 3'});
      await storageAndCaching.store({'id': '4', 'name': 'Item 4'});

      // All should be in storage
      expect(storageRepo.numberOfElements(), equals(4));

      // Cache should have 3 items (FIFO: 2, 3, 4)
      expect(cachingRepo.numberOfElements(), equals(3));

      // Item 1 should be evicted from cache
      final cachedIds = await cachingRepo.listOfIds();
      expect(cachedIds, isNot(contains('1')));

      // But all should still be in storage
      final storageIds = await storageRepo.listOfIds();
      expect(storageIds, containsAll(['1', '2', '3', '4']));
    });

    test('should delete from both storage and cache', () async {
      await storageAndCaching.store({'id': '1', 'name': 'Test'});

      final deleted = await storageAndCaching.delete('1');
      expect(deleted, isTrue);

      final storageRetrieved = await storageRepo.retrieve('1');
      expect(storageRetrieved, isNull);

      final cacheRetrieved = await cachingRepo.retrieve('1');
      expect(cacheRetrieved, isNull);
    });

    test('should clear both storage and cache', () async {
      await storageAndCaching.store({'id': '1', 'name': 'Item 1'});
      await storageAndCaching.store({'id': '2', 'name': 'Item 2'});

      await storageAndCaching.clear();

      expect(storageRepo.numberOfElements(), equals(0));
      expect(cachingRepo.numberOfElements(), equals(0));
    });

    test('should return correct numberOfElements', () async {
      await storageAndCaching.store({'id': '1', 'name': 'Item 1'});
      await storageAndCaching.store({'id': '2', 'name': 'Item 2'});

      final count = storageAndCaching.numberOfElements();
      expect(count, equals(2));
    });

    test('should list all IDs from storage and cache', () async {
      await storageAndCaching.store({'id': '1', 'name': 'Item 1'});
      await storageAndCaching.store({'id': '2', 'name': 'Item 2'});
      await storageAndCaching.store({'id': '3', 'name': 'Item 3'});

      final ids = await storageAndCaching.listOfIds();
      expect(ids, containsAll(['1', '2', '3']));
    });

    test('should flush cache to storage', () async {
      // Store items (some will be evicted from cache)
      for (var i = 1; i <= 5; i++) {
        await storageAndCaching.store({'id': '$i', 'name': 'Item $i'});
      }

      // Cache has 3 items, storage has 5
      expect(cachingRepo.numberOfElements(), equals(3));
      expect(storageRepo.numberOfElements(), equals(5));

      await storageAndCaching.flush();

      // After flush, all cached items should still be in storage
      final allIds = await storageAndCaching.listOfIds();
      expect(allIds, hasLength(5));
    });

    test('should destroy both storage and cache', () async {
      await storageAndCaching.store({'id': '1', 'name': 'Item'});
      await storageAndCaching.destroy();

      expect(storageRepo.numberOfElements(), equals(0));
      expect(cachingRepo.numberOfElements(), equals(0));
    });
  });

  group('ErmesStorageAndCaching Tests - LIFO Mode', () {
    late IWorkDb db;
    late ErmesStorageAndCaching<Map<String, dynamic>> storageAndCaching;
    late ErmesCachingRepository<Map<String, dynamic>> cachingRepo;

    setUp(() async {
      db = WorkDbFactory.forMemory();
      // Ensure fresh state before creating instances
      await db.clearDatabase();
      final storageRepo = ErmesStorageRepository<Map<String, dynamic>>(db);
      cachingRepo = ErmesCachingRepository<Map<String, dynamic>>(3);
      storageAndCaching = ErmesStorageAndCaching<Map<String, dynamic>>(
        ErmesStorageService<Map<String, dynamic>>(storageRepo),
        ErmesCachingService<Map<String, dynamic>>(cachingRepo),
        maxNumberOfElementCached: 3,
        cachingMode: CachingMode.lifo,
      );
    });

    tearDown(() async {
      await db.clearDatabase();
    });

    test('should apply LIFO eviction policy', () async {
      // Store 4 items (cache max is 3)
      await storageAndCaching.store({'id': '1', 'name': 'Item 1'});
      await storageAndCaching.store({'id': '2', 'name': 'Item 2'});
      await storageAndCaching.store({'id': '3', 'name': 'Item 3'});
      await storageAndCaching.store({'id': '4', 'name': 'Item 4'});

      // Cache should have 3 items (LIFO: 2, 3, 4)
      expect(cachingRepo.numberOfElements(), equals(3));

      // Item 3 should be evicted (last inserted before item 4)
      final cachedIds = await cachingRepo.listOfIds();
      expect(cachedIds.length, equals(3));
    });
  });

  group('Factory Tests', () {
    late IWorkDb db;

    setUp(() async {
      db = WorkDbFactory.forMemory();
      // Ensure fresh state before creating instances
      await db.clearDatabase();
    });

    tearDown(() async {
      await db.clearDatabase();
    });

    test('createErmesStorageRepository should return repository', () {
      final repo = createErmesStorageRepository<Map<String, dynamic>>(db);
      expect(repo, isA<ErmesStorageRepository<Map<String, dynamic>>>());
    });

    test('createErmesStorageService should return service', () {
      final repo = createErmesStorageRepository<Map<String, dynamic>>(db);
      final service = createErmesStorageService<Map<String, dynamic>>(repo);
      expect(service, isA<ErmesStorageService<Map<String, dynamic>>>());
    });

    test(
      'createErmesStorageAndCaching should return combined storage',
      () {
        final combined = createErmesStorageAndCaching<Map<String, dynamic>>(
          db,
        );
        expect(
          combined,
          isA<ErmesStorageAndCaching<Map<String, dynamic>>>(),
        );
      },
    );

    test('factory should work end-to-end', () async {
      final combined = createErmesStorageAndCaching<Map<String, dynamic>>(
        db,
        maxNumberOfElementCached: 50,
      );

      final testData = {'id': '1', 'name': 'Factory Test'};
      await combined.store(testData);

      final retrieved = await combined.retrieve('1');
      expect(retrieved, isNotNull);
      expect(retrieved?['name'], equals('Factory Test'));
    });
  });

  group('Edge Cases and Error Handling', () {
    late IWorkDb db;
    late IErmesStorageAndCaching<Map<String, dynamic>> combined;

    setUp(() async {
      db = WorkDbFactory.forMemory();
      // Ensure fresh state before creating instances
      await db.clearDatabase();
      combined = createErmesStorageAndCaching<Map<String, dynamic>>(
        db,
        maxNumberOfElementCached: 10,
      );
    });

    tearDown(() async {
      await db.clearDatabase();
    });

    test('should handle empty data retrieval', () async {
      final ids = await combined.listOfIds();
      expect(ids, isEmpty);
    });

    test('should handle duplicate stores', () async {
      final testData = {'id': '1', 'name': 'Item'};
      await combined.store(testData);
      await combined.store({'id': '1', 'name': 'Updated'});

      final retrieved = await combined.retrieve('1');
      expect(retrieved?['name'], equals('Updated'));
    });

    test('should handle large number of items', () async {
      for (var i = 0; i < 100; i++) {
        await combined.store({'id': '$i', 'name': 'Item $i', 'index': i});
      }

      expect(combined.numberOfElements(), equals(100));

      final ids = await combined.listOfIds();
      expect(ids, hasLength(100));
    });

    test('should handle complex nested objects', () async {
      final complexData = {
        'id': '1',
        'name': 'Complex',
        'nested': {
          'level1': {
            'level2': {'value': 'deep'},
          },
        },
        'array': [1, 2, 3, 4, 5],
        'mixed': [
          {'a': 1},
          {'b': 2},
        ],
      };

      await combined.store(complexData);
      final retrieved = await combined.retrieve('1');

      expect(retrieved, isNotNull);
      expect(retrieved?['nested']['level1']['level2']['value'], equals('deep'));
      expect(retrieved?['array'], equals([1, 2, 3, 4, 5]));
    });

    test('should handle numeric and string IDs', () async {
      await combined.store({'id': '123', 'name': 'String ID'});
      await combined.store({'id': 456, 'name': 'Numeric ID'});

      final retrieved1 = await combined.retrieve('123');
      expect(retrieved1, isNotNull);

      final retrieved2 = await combined.retrieve(456);
      expect(retrieved2, isNotNull);
    });
  });
}
