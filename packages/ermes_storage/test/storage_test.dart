import 'dart:typed_data';

import 'package:ermes_storage/ermes_storage.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

Uint8List _testData(String value) => Uint8List.fromList(value.codeUnits);

void main() {
  group('ErmesCachingRepository Tests', () {
    late ErmesCachingRepository<MessageType> repository;

    setUp(() {
      repository = ErmesCachingRepository<MessageType>(100);
    });

    tearDown(() async {
      await repository.destroy();
    });

    test('should store and retrieve a message', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await repository.store(message);
      final retrieved = await repository.retrieve(1);

      expect(retrieved, isNotNull);
      expect(
        retrieved?.when(
          data: (msg) => msg.id,
          chunk: (msg) => msg.id,
          service: (msg) => msg.id,
        ),
        equals(1),
      );
    });

    test('should delete a message', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await repository.store(message);
      final deleted = await repository.delete(1);

      expect(deleted, isTrue);
      expect(await repository.retrieve(1), isNull);
    });

    test('should clear all messages', () async {
      await repository.store(
        MessageType.data(MessageData(id: 1, data: _testData('test1'))),
      );
      await repository.store(
        MessageType.data(MessageData(id: 2, data: _testData('test2'))),
      );

      expect(repository.numberOfElements(), equals(2));

      await repository.clear();

      expect(repository.numberOfElements(), equals(0));
    });

    test('should list all message IDs', () async {
      await repository.store(
        MessageType.data(MessageData(id: 1, data: _testData('test1'))),
      );
      await repository.store(
        MessageType.data(MessageData(id: 2, data: _testData('test2'))),
      );
      await repository.store(
        MessageType.data(MessageData(id: 3, data: _testData('test3'))),
      );

      final ids = await repository.listOfIds();

      expect(ids.length, equals(3));
      expect(ids, containsAll([1, 2, 3]));
    });

    test('should respect maximum buffer size and FIFO eviction', () async {
      final smallRepo = ErmesCachingRepository<MessageType>(2);

      await smallRepo.store(
        MessageType.data(MessageData(id: 1, data: _testData('first'))),
      );
      await smallRepo.store(
        MessageType.data(MessageData(id: 2, data: _testData('second'))),
      );

      expect(smallRepo.numberOfElements(), equals(2));

      // Adding third message should evict the first one (FIFO)
      await smallRepo.store(
        MessageType.data(MessageData(id: 3, data: _testData('third'))),
      );

      expect(smallRepo.numberOfElements(), equals(2));
      expect(await smallRepo.retrieve(1), isNull); // First was evicted
      expect(await smallRepo.retrieve(2), isNotNull);
      expect(await smallRepo.retrieve(3), isNotNull);

      await smallRepo.destroy();
    });
  });

  group('ErmesCachingService Tests', () {
    late ErmesCachingService<MessageType> service;
    late ErmesCachingRepository<MessageType> repository;

    setUp(() {
      repository = ErmesCachingRepository<MessageType>(100);
      service = ErmesCachingService<MessageType>(repository);
    });

    tearDown(() async {
      await service.destroy();
    });

    test('should delegate store to repository', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await service.store(message);

      expect(service.numberOfElements(), equals(1));
    });

    test('should delegate retrieve to repository', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await service.store(message);
      final retrieved = await service.retrieve(1);

      expect(retrieved, isNotNull);
    });

    test('should delegate delete to repository', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await service.store(message);
      final deleted = await service.delete(1);

      expect(deleted, isTrue);
      expect(await service.retrieve(1), isNull);
    });

    test('should return message count', () async {
      await service.store(
        MessageType.data(MessageData(id: 1, data: _testData('test1'))),
      );
      await service.store(
        MessageType.data(MessageData(id: 2, data: _testData('test2'))),
      );

      expect(service.numberOfElements(), equals(2));
    });
  });

  group('ErmesStorageRepository Tests', () {
    late ErmesStorageRepository<MessageType> repository;
    late IWorkDb db;

    setUp(() {
      db = WorkDbFactory.createMemory();
      repository = ErmesStorageRepository<MessageType>(db);
    });

    tearDown(() async {
      await repository.destroy();
    });

    test('should store and retrieve a message', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await repository.store(message);
      final retrieved = await repository.retrieve(1);

      expect(retrieved, isNotNull);
      expect(
        retrieved?.when(
          data: (msg) => msg.id,
          chunk: (msg) => msg.id,
          service: (msg) => msg.id,
        ),
        equals(1),
      );
    });

    test('should delete a message', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await repository.store(message);
      final deleted = await repository.delete(1);

      expect(deleted, isTrue);
      expect(await repository.retrieve(1), isNull);
    });

    test('should clear all messages', () async {
      await repository.store(
        MessageType.data(MessageData(id: 1, data: _testData('test1'))),
      );
      await repository.store(
        MessageType.data(MessageData(id: 2, data: _testData('test2'))),
      );

      await repository.clear();

      expect(repository.numberOfElements(), equals(0));
    });

    test('should list all message IDs', () async {
      await repository.store(
        MessageType.data(MessageData(id: 1, data: _testData('test1'))),
      );
      await repository.store(
        MessageType.data(MessageData(id: 2, data: _testData('test2'))),
      );
      await repository.store(
        MessageType.data(MessageData(id: 3, data: _testData('test3'))),
      );

      final ids = await repository.listOfIds();

      expect(ids.length, equals(3));
      expect(ids, containsAll([1, 2, 3]));
    });
  });

  group('ErmesStorageService Tests', () {
    late ErmesStorageService<MessageType> service;
    late ErmesStorageRepository<MessageType> repository;
    late IWorkDb db;

    setUp(() {
      db = WorkDbFactory.createMemory();
      repository = ErmesStorageRepository<MessageType>(db);
      service = ErmesStorageService<MessageType>(repository);
    });

    tearDown(() async {
      await service.destroy();
    });

    test('should delegate store to repository', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await service.store(message);

      expect(service.numberOfElements(), equals(1));
    });

    test('should delegate retrieve to repository', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await service.store(message);
      final retrieved = await service.retrieve(1);

      expect(retrieved, isNotNull);
    });

    test('should delegate delete to repository', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await service.store(message);
      final deleted = await service.delete(1);

      expect(deleted, isTrue);
      expect(await service.retrieve(1), isNull);
    });
  });

  group('ErmesStorageAndCaching Tests', () {
    late ErmesStorageAndCaching<MessageType> combined;
    late ErmesStorageRepository<MessageType> storageRepo;
    late ErmesCachingService<MessageType> cachingService;
    late IWorkDb db;

    setUp(() {
      db = WorkDbFactory.createMemory();
      storageRepo = ErmesStorageRepository<MessageType>(db);
      final cachingRepo = ErmesCachingRepository<MessageType>(50);
      cachingService = ErmesCachingService<MessageType>(cachingRepo);

      combined = ErmesStorageAndCaching<MessageType>(
        storageRepo,
        cachingService,
        maxNumberOfElementCached: 50,
      );
    });

    tearDown(() async {
      await combined.destroy();
    });

    test('should store messages in both storage and cache', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await combined.store(message);

      expect(combined.numberOfElements(), equals(1));
      expect(await combined.retrieve(1), isNotNull);
    });

    test('should retrieve from cache first', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await combined.store(message);
      final retrieved = await combined.retrieve(1);

      expect(retrieved, isNotNull);
      expect(
        retrieved?.when(
          data: (msg) => msg.id,
          chunk: (msg) => msg.id,
          service: (msg) => msg.id,
        ),
        equals(1),
      );
    });

    test('should delete from both storage and cache', () async {
      final message = MessageType.data(MessageData(id: 1, data: _testData('test')));

      await combined.store(message);
      final deleted = await combined.delete(1);

      expect(deleted, isTrue);
      expect(await combined.retrieve(1), isNull);
    });

    test('should maintain data consistency with FIFO eviction', () async {
      const maxCache = 3;
      final smallCachingRepo = ErmesCachingRepository<MessageType>(maxCache);
      final smallCachingService = ErmesCachingService<MessageType>(
        smallCachingRepo,
      );
      final smallCombined = ErmesStorageAndCaching<MessageType>(
        storageRepo,
        smallCachingService,
        maxNumberOfElementCached: maxCache,
      );

      // Store 5 messages
      for (var i = 1; i <= 5; i++) {
        await smallCombined.store(
          MessageType.data(MessageData(id: i, data: _testData('msg-$i'))),
        );
      }

      expect(smallCombined.numberOfElements(), equals(5));

      // All should be retrievable from storage
      for (var i = 1; i <= 5; i++) {
        expect(await smallCombined.retrieve(i), isNotNull);
      }

      await smallCombined.destroy();
    });
  });
}



