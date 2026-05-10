import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('ErmesSymmetricKeyRepository', () {
    late IWorkDb db;
    late ErmesSymmetricKeyRepository repo;

    StorageSymmetricKeyType createKey(int id) => StorageSymmetricKeyType(
      expiration: DateTime(2026, 1, 1),
      key: 'key_$id',
      idPeer: '$id',
    );

    setUp(() {
      db = WorkDb.memory();
      repo = ErmesSymmetricKeyRepository(db);
    });

    tearDown(() async {
      await repo.destroy();
    });

    test('should store and retrieve a key', () async {
      await repo.store(createKey(1));
      final retrieved = await repo.retrieve(1);
      expect(retrieved, isNotNull);
      expect(retrieved!.key, equals('key_1'));
    });

    test('should return null for non-existent key', () async {
      expect(await repo.retrieve(999), isNull);
    });

    test('should overwrite existing key', () async {
      await repo.store(StorageSymmetricKeyType(
        expiration: DateTime(2026, 1, 1),
        key: 'old_key',
        idPeer: '1',
      ));
      await repo.store(StorageSymmetricKeyType(
        expiration: DateTime(2026, 6, 1),
        key: 'new_key',
        idPeer: '1',
      ));

      final retrieved = await repo.retrieve(1);
      expect(retrieved!.key, equals('new_key'));
      expect(retrieved.expiration, equals(DateTime(2026, 6, 1)));
    });

    test('should delete a key', () async {
      await repo.store(createKey(1));
      final deleted = await repo.delete(1);
      expect(deleted, isTrue);
      expect(await repo.retrieve(1), isNull);
    });

    test('should return false when deleting non-existent key', () async {
      expect(await repo.delete(999), isFalse);
    });

    test('should track numberOfElements', () async {
      expect(repo.numberOfElements(), equals(0));
      await repo.store(createKey(1));
      expect(repo.numberOfElements(), equals(1));
      await repo.store(createKey(2));
      expect(repo.numberOfElements(), equals(2));
      await repo.delete(1);
      expect(repo.numberOfElements(), equals(1));
    });

    test('should list all key IDs', () async {
      await repo.store(createKey(10));
      await repo.store(createKey(20));
      final ids = await repo.listOfIds();
      expect(ids, containsAll([10, 20]));
    });

    test('should clear all keys', () async {
      await repo.store(createKey(1));
      await repo.store(createKey(2));
      await repo.clear();
      expect(repo.numberOfElements(), equals(0));
    });

    test('should support custom collection', () async {
      final customRepo = ErmesSymmetricKeyRepository(db, 'my_keys');
      await customRepo.store(createKey(1));
      expect(await customRepo.retrieve(1), isNotNull);
      await customRepo.destroy();
    });
  });

  group('ErmesSymmetricKeyService', () {
    late IWorkDb db;
    late ErmesSymmetricKeyRepository repo;
    late ErmesSymmetricKeyService service;

    StorageSymmetricKeyType createKey(int id) => StorageSymmetricKeyType(
      expiration: DateTime(2026, 1, 1),
      key: 'key_$id',
      idPeer: '$id',
    );

    setUp(() {
      db = WorkDb.memory();
      repo = ErmesSymmetricKeyRepository(db);
      service = ErmesSymmetricKeyService(repo);
    });

    tearDown(() async {
      await service.destroy();
    });

    test('should delegate store and retrieve', () async {
      await service.store(createKey(1));
      expect((await service.retrieve(1))!.key, equals('key_1'));
    });

    test('should delegate delete', () async {
      await service.store(createKey(1));
      await service.delete(1);
      expect(await service.retrieve(1), isNull);
    });

    test('should delegate clear', () async {
      await service.store(createKey(1));
      await service.store(createKey(2));
      await service.clear();
      expect(service.numberOfElements(), equals(0));
    });

    test('should delegate listOfIds', () async {
      await service.store(createKey(1));
      final ids = await service.listOfIds();
      expect(ids, contains(1));
    });
  });
}
