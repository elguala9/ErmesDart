import 'dart:typed_data';

import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('createErmesCachingRepository', () {
    test('should create repository with default buffer', () {
      final repo = createErmesCachingRepository<MessageRootStorage>();
      expect(repo, isNotNull);
      expect(repo.numberOfElements(), equals(0));
    });

    test('should create repository with custom buffer', () {
      final repo = createErmesCachingRepository<MessageRootStorage>(50);
      expect(repo, isNotNull);
    });
  });

  group('createErmesCachingService', () {
    test('should create service with default repository', () {
      final service = createErmesCachingService<MessageRootStorage>();
      expect(service, isNotNull);
      expect(service.numberOfElements(), equals(0));
    });

    test('should create service with custom repository', () {
      final repo = createErmesCachingRepository<MessageRootStorage>(10);
      final service = createErmesCachingService<MessageRootStorage>(repo);
      expect(service, isNotNull);
    });
  });

  group('createErmesStorageRepository', () {
    test('should create repository with given db', () {
      final db = WorkDb.memory();
      final repo = createErmesStorageRepository<MessageRootStorage>(db);
      expect(repo, isNotNull);
      expect(repo.numberOfElements(), equals(0));
    });

    test('should create repository with custom collection', () {
      final db = WorkDb.memory();
      final repo = createErmesStorageRepository<MessageRootStorage>(
        db,
        collection: 'custom',
      );
      expect(repo, isNotNull);
    });

    test('should create repository with fromJson factory', () {
      final db = WorkDb.memory();
      final repo = createErmesStorageRepository<MessageRootStorage>(
        db,
        fromJsonFactory: MessageRootStorage.fromJson,
      );
      expect(repo, isNotNull);
    });
  });

  group('createErmesStorageService', () {
    test('should create service with given repository', () {
      final db = WorkDb.memory();
      final repo = createErmesStorageRepository<MessageRootStorage>(db);
      final service = createErmesStorageService(repo);
      expect(service, isNotNull);
    });

    test('should delegate operations through service', () async {
      final db = WorkDb.memory();
      final repo = createErmesStorageRepository<MessageRootStorage>(
        db,
        fromJsonFactory: MessageRootStorage.fromJson,
      );
      final service = createErmesStorageService(repo);

      await service.store(MessageRootStorage(
        id: 1,
        messageSerialized: Uint8List.fromList([1]),
        integrityCheckValue: 'test',
      ));

      expect((await service.retrieve(1))!.id, equals(1));
      await service.destroy();
    });
  });

  group('createErmesStorageAndCaching', () {
    test('should create combined system', () {
      final db = WorkDb.memory();
      final system = createErmesStorageAndCaching<MessageRootStorage>(db);
      expect(system, isNotNull);
    });

    test('should create system with custom options', () {
      final db = WorkDb.memory();
      final system = createErmesStorageAndCaching<MessageRootStorage>(
        db,
        collection: 'custom',
        maxNumberOfElementCached: 50,
        cachingMode: CachingMode.lifo,
      );
      expect(system, isNotNull);
    });

    test('should store and retrieve through factory-created system', () async {
      final db = WorkDb.memory();
      final repo = createErmesStorageRepository<MessageRootStorage>(
        db,
        fromJsonFactory: MessageRootStorage.fromJson,
      );
      final service = createErmesStorageService(repo);
      final cachingRepo = createErmesCachingRepository<MessageRootStorage>(100);
      final cachingService =
          createErmesCachingService<MessageRootStorage>(cachingRepo);
      final system = ErmesStorageAndCaching<MessageRootStorage>(
        service,
        cachingService,
      );

      await system.store(MessageRootStorage(
        id: 1,
        messageSerialized: Uint8List.fromList([1]),
        integrityCheckValue: 'test',
      ));

      expect((await system.retrieve(1))!.id, equals(1));
      await system.destroy();
    });
  });

  group('createErmesSymmetricKeyRepository', () {
    test('should create repository', () {
      final db = WorkDb.memory();
      final repo = createErmesSymmetricKeyRepository(db);
      expect(repo, isNotNull);
    });

    test('should create repository with custom collection', () {
      final db = WorkDb.memory();
      final repo = createErmesSymmetricKeyRepository(
        db,
        collection: 'custom_keys',
      );
      expect(repo, isNotNull);
    });
  });

  group('createErmesSymmetricKeyService', () {
    test('should create service', () {
      final db = WorkDb.memory();
      final repo = createErmesSymmetricKeyRepository(db);
      final service = createErmesSymmetricKeyService(repo);
      expect(service, isNotNull);
    });

    test('should delegate operations', () async {
      final db = WorkDb.memory();
      final repo = createErmesSymmetricKeyRepository(db);
      final service = createErmesSymmetricKeyService(repo);

      await service.store(StorageSymmetricKeyType(
        expiration: DateTime(2026),
        key: 'my_key',
        idPeer: '1',
      ));

      expect((await service.retrieve(1))!.key, equals('my_key'));
      await service.destroy();
    });
  });
}
