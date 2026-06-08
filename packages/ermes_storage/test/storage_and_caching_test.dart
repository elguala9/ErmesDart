import 'dart:typed_data';

import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('ErmesStorageAndCaching', () {
    late IWorkDb db;
    late ErmesStorageRepository<MessageRootStorage> storageRepo;
    late ErmesStorageService<MessageRootStorage> storageService;
    late ErmesCachingRepository<MessageRootStorage> cachingRepo;
    late ErmesCachingService<MessageRootStorage> cachingService;
    late ErmesStorageAndCaching<MessageRootStorage> system;

    MessageRootStorage createMessage(int id) => MessageRootStorage(
      id: id,
      messageSerialized: Uint8List.fromList([id]),
      integrityCheckValue: 'check$id',
    );

    setUp(() {
      db = WorkDb.memory();
      storageRepo = ErmesStorageRepository<MessageRootStorage>(
        db,
        ErmesStorageRepository.defaultCollection,
        MessageRootStorage.fromJson,
      );
      storageService = ErmesStorageService<MessageRootStorage>(storageRepo);
      cachingRepo = ErmesCachingRepository<MessageRootStorage>(3);
      cachingService = ErmesCachingService<MessageRootStorage>(cachingRepo);
      system = ErmesStorageAndCaching<MessageRootStorage>(
        storageService,
        cachingService,
        maxNumberOfElementCached: 3,
      );
    });

    tearDown(() async {
      await system.destroy();
    });

    test('should store data in both storage and cache', () async {
      await system.store(createMessage(1));
      final retrieved = await system.retrieve(1);
      expect(retrieved!.id, equals(1));
    });

    test('should retrieve from cache first', () async {
      await system.store(createMessage(1));
      await cachingRepo.clear();
      final retrieved = await system.retrieve(1);
      expect(retrieved!.id, equals(1));
    });

    test('should return null for unknown id', () async {
      expect(await system.retrieve(999), isNull);
    });

    test('should delete from both storage and cache', () async {
      await system.store(createMessage(1));
      final deleted = await system.delete(1);
      expect(deleted, isTrue);
      expect(await system.retrieve(1), isNull);
    });

    test('should clear both storage and cache', () async {
      await system.store(createMessage(1));
      await system.store(createMessage(2));
      await system.clear();
      expect(system.numberOfElements(), equals(0));
    });

    test('should flush cache to storage', () async {
      await system.store(createMessage(1));
      await storageRepo.clear();

      await system.flush();

      await cachingRepo.clear();
      final retrieved = await system.retrieve(1);
      expect(retrieved!.id, equals(1));
    });

    test('should list combined IDs', () async {
      await system.store(createMessage(1));
      await cachingRepo.store(createMessage(2));
      final ids = await system.listOfIds();
      expect(ids, containsAll([1, 2]));
    });

    test('should enforce FIFO eviction policy', () async {
      await system.store(createMessage(1));
      await system.store(createMessage(2));
      await system.store(createMessage(3));
      await system.store(createMessage(4));

      expect(await cachingRepo.retrieve(1), isNull);
      expect(await cachingRepo.retrieve(2), isNotNull);
      expect(await cachingRepo.retrieve(3), isNotNull);
      expect(await cachingRepo.retrieve(4), isNotNull);
    });

    test('should destroy both storage and cache', () async {
      await system.store(createMessage(1));
      await system.destroy();
      expect(system.numberOfElements(), equals(0));
    });
  });

  group('ErmesStorageAndCaching with LIFO mode', () {
    late IWorkDb db;
    late ErmesCachingRepository<MessageRootStorage> cachingRepo;
    late ErmesStorageAndCaching<MessageRootStorage> system;

    MessageRootStorage createMessage(int id) => MessageRootStorage(
      id: id,
      messageSerialized: Uint8List.fromList([id]),
      integrityCheckValue: 'check$id',
    );

    setUp(() {
      db = WorkDb.memory();
      final storageRepo = ErmesStorageRepository<MessageRootStorage>(
        db,
        ErmesStorageRepository.defaultCollection,
        MessageRootStorage.fromJson,
      );
      final storageService =
          ErmesStorageService<MessageRootStorage>(storageRepo);
      cachingRepo = ErmesCachingRepository<MessageRootStorage>(3);
      final cachingService =
          ErmesCachingService<MessageRootStorage>(cachingRepo);
      system = ErmesStorageAndCaching<MessageRootStorage>(
        storageService,
        cachingService,
        maxNumberOfElementCached: 3,
        cachingMode: CachingMode.lifo,
      );
    });

    tearDown(() async {
      await system.destroy();
    });

    test('should evict newest element with LIFO policy', () async {
      await system.store(createMessage(1));
      await system.store(createMessage(2));
      await system.store(createMessage(3));
      await system.store(createMessage(4));

      expect(await cachingRepo.retrieve(1), isNotNull);
      expect(await cachingRepo.retrieve(2), isNotNull);
      expect(await cachingRepo.retrieve(3), isNull);
      expect(await cachingRepo.retrieve(4), isNotNull);
    });
  });
}
