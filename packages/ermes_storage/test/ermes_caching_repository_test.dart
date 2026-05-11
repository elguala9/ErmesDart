import 'dart:typed_data';

import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('ErmesCachingRepository', () {
    late ErmesCachingRepository<MessageRootStorage> cache;

    setUp(() {
      cache = ErmesCachingRepository<MessageRootStorage>(3);
    });

    MessageRootStorage createMessage(int id) => MessageRootStorage(
      id: id,
      messageSerialized: Uint8List.fromList([id]),
      integrityCheckValue: 'check$id',
    );

    test('should store and retrieve data', () async {
      await cache.store(createMessage(1));

      final retrieved = await cache.retrieve(1);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(1));
    });

    test('should return null for unknown id', () async {
      final retrieved = await cache.retrieve(999);
      expect(retrieved, isNull);
    });

    test('should delete data', () async {
      await cache.store(createMessage(1));
      final deleted = await cache.delete(1);

      expect(deleted, isTrue);
      final retrieved = await cache.retrieve(1);
      expect(retrieved, isNull);
    });

    test('should return false when deleting non-existent data', () async {
      final deleted = await cache.delete(999);
      expect(deleted, isFalse);
    });

    test('should evict oldest when exceeding maxBuffer', () async {
      await cache.store(createMessage(1));
      await cache.store(createMessage(2));
      await cache.store(createMessage(3));
      await cache.store(createMessage(4));

      final evicted = await cache.retrieve(1);
      expect(evicted, isNull);
      expect(cache.numberOfElements(), equals(3));
    });

    test('should update existing item without eviction', () async {
      await cache.store(createMessage(1));
      await cache.store(createMessage(1));

      expect(cache.numberOfElements(), equals(1));
    });

    test('should list all IDs', () async {
      await cache.store(createMessage(1));
      await cache.store(createMessage(2));

      final ids = await cache.listOfIds();
      expect(ids, containsAll([1, 2]));
    });

    test('should clear all data', () async {
      await cache.store(createMessage(1));
      await cache.store(createMessage(2));

      await cache.clear();
      expect(cache.numberOfElements(), equals(0));
    });
  });
}
