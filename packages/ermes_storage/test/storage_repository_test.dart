import 'dart:typed_data';

import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('ErmesStorageRepository', () {
    late IWorkDb db;
    late ErmesStorageRepository<MessageRootStorage> repo;

    MessageRootStorage createMessage(int id) => MessageRootStorage(
      id: id,
      messageSerialized: Uint8List.fromList([id]),
      integrityCheckValue: 'check$id',
    );

    setUp(() {
      db = WorkDb.memory();
      repo = ErmesStorageRepository<MessageRootStorage>(
        db,
        ErmesStorageRepository.defaultCollection,
        MessageRootStorage.fromJson,
      );
    });

    tearDown(() async {
      await repo.destroy();
    });

    test('should store and retrieve data', () async {
      await repo.store(createMessage(1));
      final retrieved = await repo.retrieve(1);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(1));
    });

    test('should return null for unknown id', () async {
      final retrieved = await repo.retrieve(999);
      expect(retrieved, isNull);
    });

    test('should update existing item', () async {
      await repo.store(createMessage(1));
      await repo.store(MessageRootStorage(
        id: 1,
        messageSerialized: Uint8List.fromList([99]),
        integrityCheckValue: 'updated',
      ));

      final retrieved = await repo.retrieve(1);
      expect(retrieved, isNotNull);
      expect(retrieved!.integrityCheckValue, equals('updated'));
    });

    test('should delete data', () async {
      await repo.store(createMessage(1));
      final deleted = await repo.delete(1);
      expect(deleted, isTrue);
      expect(await repo.retrieve(1), isNull);
    });

    test('should return false when deleting non-existent data', () async {
      final deleted = await repo.delete(999);
      expect(deleted, isFalse);
    });

    test('should track numberOfElements', () async {
      expect(repo.numberOfElements(), equals(0));
      await repo.store(createMessage(1));
      expect(repo.numberOfElements(), equals(1));
      await repo.store(createMessage(2));
      expect(repo.numberOfElements(), equals(2));
      await repo.delete(1);
      expect(repo.numberOfElements(), equals(1));
    });

    test('should clear all data', () async {
      await repo.store(createMessage(1));
      await repo.store(createMessage(2));
      await repo.clear();
      expect(repo.numberOfElements(), equals(0));
      expect(await repo.retrieve(1), isNull);
    });

    test('should list all IDs', () async {
      await repo.store(createMessage(1));
      await repo.store(createMessage(3));
      final ids = await repo.listOfIds();
      expect(ids, containsAll([1, 3]));
    });

    test('should destroy and clear database', () async {
      await repo.store(createMessage(1));
      await repo.destroy();
      expect(repo.numberOfElements(), equals(0));
      expect(await repo.retrieve(1), isNull);
    });

    test('should support custom collection name', () async {
      final customRepo = ErmesStorageRepository<MessageRootStorage>(
        db,
        'custom_collection',
        MessageRootStorage.fromJson,
      );
      await customRepo.store(createMessage(42));
      final retrieved = await customRepo.retrieve(42);
      expect(retrieved!.id, equals(42));
      await customRepo.destroy();
    });

    test('should support custom fromJson factory', () async {
      final customRepo = ErmesStorageRepository<MessageRootStorage>(
        db,
        ErmesStorageRepository.defaultCollection,
        MessageRootStorage.fromJson,
      );
      await customRepo.store(createMessage(7));
      final retrieved = await customRepo.retrieve(7);
      expect(retrieved!.id, equals(7));
      await customRepo.destroy();
    });

    test('should isolate collections', () async {
      final repoA = ErmesStorageRepository<MessageRootStorage>(
        db, 'col_a', MessageRootStorage.fromJson,
      );
      final repoB = ErmesStorageRepository<MessageRootStorage>(
        db, 'col_b', MessageRootStorage.fromJson,
      );

      await repoA.store(createMessage(1));
      await repoB.store(createMessage(2));

      expect(await repoA.retrieve(1), isNotNull);
      expect(await repoA.retrieve(2), isNull);
      expect(await repoB.retrieve(2), isNotNull);
      expect(await repoB.retrieve(1), isNull);

      await repoA.destroy();
      await repoB.destroy();
    });
  });
}
