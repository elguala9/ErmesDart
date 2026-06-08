import 'package:ermes_storage/ermes_storage.dart';
import 'package:test/test.dart';

void main() {
  group('GenericCachingRepository', () {
    late GenericCachingRepository<String, String> cache;

    setUp(() {
      cache = GenericCachingRepository<String, String>(3);
    });

    test('should store and retrieve data', () async {
      await cache.store('key1', 'value1');

      final retrieved = await cache.retrieve('key1');
      expect(retrieved, equals('value1'));
    });

    test('should return null for unknown key', () async {
      final retrieved = await cache.retrieve('unknown');
      expect(retrieved, isNull);
    });

    test('should delete data', () async {
      await cache.store('key1', 'value1');
      final deleted = await cache.delete('key1');

      expect(deleted, isTrue);
      final retrieved = await cache.retrieve('key1');
      expect(retrieved, isNull);
    });

    test('should evict oldest when exceeding maxBuffer', () async {
      await cache.store('a', '1');
      await cache.store('b', '2');
      await cache.store('c', '3');
      await cache.store('d', '4');

      final evicted = await cache.retrieve('a');
      expect(evicted, isNull);
      expect(cache.numberOfElements(), equals(3));
    });

    test('should update existing item', () async {
      await cache.store('key1', 'value1');
      await cache.store('key1', 'value2');

      final retrieved = await cache.retrieve('key1');
      expect(retrieved, equals('value2'));
      expect(cache.numberOfElements(), equals(1));
    });

    test('should clear all data', () async {
      await cache.store('a', '1');
      await cache.store('b', '2');

      await cache.clear();
      expect(cache.numberOfElements(), equals(0));
    });
  });

  group('GenericCachingService', () {
    late GenericCachingRepository<int, String> repo;
    late GenericCachingService<int, String> service;

    setUp(() {
      repo = GenericCachingRepository<int, String>(5);
      service = GenericCachingService<int, String>(repo);
    });

    test('should delegate store and retrieve', () async {
      await service.store(1, 'hello');
      expect(await service.retrieve(1), equals('hello'));
    });

    test('should delegate delete', () async {
      await service.store(1, 'hello');
      await service.delete(1);
      expect(await service.retrieve(1), isNull);
    });

    test('should delegate clear', () async {
      await service.store(1, 'a');
      await service.store(2, 'b');
      await service.clear();
      expect(service.numberOfElements(), equals(0));
    });
  });
}
