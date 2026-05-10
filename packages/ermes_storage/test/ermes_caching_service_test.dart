import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('ErmesCachingService', () {
    late ErmesCachingRepository<MessageRootStorage> repo;
    late ErmesCachingService<MessageRootStorage> service;

    setUp(() {
      repo = ErmesCachingRepository<MessageRootStorage>(5);
      service = ErmesCachingService<MessageRootStorage>(repo);
    });

    MessageRootStorage createMessage(int id) => MessageRootStorage(
      id: id,
      messageSerialized: Uint8List.fromList([id]),
      integrityCheckValue: 'check$id',
    );

    test('should store and retrieve data', () async {
      await service.store(createMessage(1));
      final retrieved = await service.retrieve(1);
      expect(retrieved!.id, equals(1));
    });

    test('should delete data', () async {
      await service.store(createMessage(1));
      await service.delete(1);
      expect(await service.retrieve(1), isNull);
    });

    test('should clear all data', () async {
      await service.store(createMessage(1));
      await service.store(createMessage(2));
      await service.clear();
      expect(service.numberOfElements(), equals(0));
    });
  });
}
