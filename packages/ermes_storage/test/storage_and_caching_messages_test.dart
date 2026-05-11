import 'dart:typed_data';

import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('ErmesStorageAndCachingMessages', () {
    late IWorkDb db;
    late ErmesStorageAndCachingMessages<MessageRootStorage> system;

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
      final cachingRepo = ErmesCachingRepository<MessageRootStorage>(10);
      final cachingService =
          ErmesCachingService<MessageRootStorage>(cachingRepo);
      system = ErmesStorageAndCachingMessages<MessageRootStorage>(
        storageService,
        cachingService,
        maxNumberOfElementCached: 10,
      );
    });

    tearDown(() async {
      await system.destroy();
    });

    test('should store and retrieve messages', () async {
      await system.store(createMessage(1));
      final retrieved = await system.retrieve(1);
      expect(retrieved!.id, equals(1));
    });

    test('should delete messages up to given id', () async {
      for (var i = 0; i < 5; i++) {
        await system.store(createMessage(i));
      }

      system.deleteUntil(2);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await system.retrieve(0), isNull);
      expect(await system.retrieve(1), isNull);
      expect(await system.retrieve(2), isNull);
      expect(await system.retrieve(3), isNotNull);
      expect(await system.retrieve(4), isNotNull);
    });

    test('should handle deleteUntil with id beyond range', () async {
      await system.store(createMessage(0));
      system.deleteUntil(99);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await system.retrieve(0), isNull);
    });

    test('should support delete and clear inherited operations', () async {
      await system.store(createMessage(1));
      await system.store(createMessage(2));

      await system.delete(1);
      expect(await system.retrieve(1), isNull);
      expect(await system.retrieve(2), isNotNull);

      await system.clear();
      expect(system.numberOfElements(), equals(0));
    });
  });
}
