import 'dart:typed_data';

import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';
import 'package:work_db/work_db.dart';

void main() {
  group('ErmesStorageService', () {
    late IWorkDb db;
    late ErmesStorageRepository<MessageRootStorage> repo;
    late ErmesStorageService<MessageRootStorage> service;

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
      service = ErmesStorageService<MessageRootStorage>(repo);
    });

    tearDown(() async {
      await service.destroy();
    });

    test('should delegate store and retrieve', () async {
      await service.store(createMessage(1));
      final retrieved = await service.retrieve(1);
      expect(retrieved!.id, equals(1));
    });

    test('should return null for unknown id', () async {
      expect(await service.retrieve(999), isNull);
    });

    test('should delegate delete', () async {
      await service.store(createMessage(1));
      await service.delete(1);
      expect(await service.retrieve(1), isNull);
    });

    test('should delegate clear', () async {
      await service.store(createMessage(1));
      await service.store(createMessage(2));
      await service.clear();
      expect(service.numberOfElements(), equals(0));
    });

    test('should track numberOfElements', () async {
      expect(service.numberOfElements(), equals(0));
      await service.store(createMessage(1));
      expect(service.numberOfElements(), equals(1));
    });

    test('should delegate listOfIds', () async {
      await service.store(createMessage(1));
      await service.store(createMessage(2));
      final ids = await service.listOfIds();
      expect(ids, containsAll([1, 2]));
    });

    test('should delegate destroy', () async {
      await service.store(createMessage(1));
      await service.destroy();
      expect(service.numberOfElements(), equals(0));
    });
  });
}
