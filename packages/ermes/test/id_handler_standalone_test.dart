// Test file per IdHandler senza dipendenze problematiche
// Evita l'import di ermes che causa problemi con ShspInstance

import 'package:ermes/src/ermes_implementation/id_handler/id_handler_repository.dart';
import 'package:ermes/src/ermes_implementation/id_handler/id_handler_service.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:test/test.dart';

void main() {
  group('IdHandlerRepository Tests', () {
    late IdHandlerRepository repository;

    setUp(() {
      repository = IdHandlerRepository();
    });

    test('should generate sequential IDs starting from 0', () {
      expect(repository.getNewId(), equals(0));
      expect(repository.getNewId(), equals(1));
      expect(repository.getNewId(), equals(2));
    });

    test('should maintain current counter', () {
      repository.getNewId();
      repository.getNewId();
      expect(repository.getCurrent(), equals(2));
    });

    test('should reset counter to initial value', () {
      repository.getNewId();
      repository.getNewId();
      repository.reset();
      expect(repository.getCurrent(), equals(0));
      expect(repository.getNewId(), equals(0));
    });

    test('should set counter to specific value', () {
      repository.setCounter(100);
      expect(repository.getCurrent(), equals(100));
      expect(repository.getNewId(), equals(100));
    });

    test('should handle data consistency during rapid generation', () {
      final ids = <int>[];
      for (var i = 0; i < 100; i++) {
        ids.add(repository.getNewId());
      }

      for (var i = 0; i < 100; i++) {
        expect(ids[i], equals(i));
      }
      expect(repository.getCurrent(), equals(100));
    });

    test('should maintain counter state across operations', () {
      expect(repository.getCurrent(), equals(0));
      expect(repository.getNewId(), equals(0));
      expect(repository.getCurrent(), equals(1));
      expect(repository.getNewId(), equals(1));
      expect(repository.getCurrent(), equals(2));
    });

    test('should handle multiple resets', () {
      repository.getNewId();
      repository.getNewId();
      repository.reset();

      for (var i = 0; i < 5; i++) {
        repository.getNewId();
      }

      repository.reset();
      expect(repository.getCurrent(), equals(0));
    });

    test('should handle setCounter at different positions', () {
      repository.getNewId();
      repository.setCounter(50);
      expect(repository.getCurrent(), equals(50));
      expect(repository.getNewId(), equals(50));
      expect(repository.getNewId(), equals(51));
    });
  });

  group('IdHandlerService Tests', () {
    late IdHandlerService service;

    setUp(() {
      service = IdHandlerService(repo: IdHandlerRepository());
    });

    test('should generate IDs through service', () {
      expect(service.getNewId(), equals(0));
      expect(service.getNewId(), equals(1));
      expect(service.getNewId(), equals(2));
    });

    test('should reset through service', () {
      service.getNewId();
      service.getNewId();
      service.reset();
      expect(service.getNewId(), equals(0));
    });

    test('should handle rapid ID generation', () {
      final ids = <int>[];
      for (var i = 0; i < 50; i++) {
        ids.add(service.getNewId());
      }

      for (var i = 0; i < 50; i++) {
        expect(ids[i], equals(i));
      }
    });

    test('should maintain data consistency', () {
      for (var i = 0; i < 100; i++) {
        final id = service.getNewId();
        expect(id, equals(i));
      }
    });
  });

  group('IdHandlerRepository with Caching Tests', () {
    late IdHandlerRepository repository;
    late IErmesCachingRepository<Map<String, dynamic>> cache;

    setUp(() {
      repository = IdHandlerRepository();
      cache = createErmesCachingRepository<Map<String, dynamic>>();
    });

    tearDown(() async {
      await cache.destroy();
    });

    test('should generate IDs and store in cache without collision', () async {
      final ids = <int>[];

      for (var i = 0; i < 50; i++) {
        final id = repository.getNewId();
        ids.add(id);

        await cache.store({
          'id': '$id',
          'sequence': i,
          'generated_at': DateTime.now().toIso8601String(),
        });
      }

      expect(ids.toSet().length, equals(50));
      for (var i = 0; i < 50; i++) {
        expect(ids[i], equals(i));
      }

      expect(cache.numberOfElements(), equals(50));
    });

    test('should maintain data consistency during mixed operations', () async {
      repository.setCounter(100);

      for (var i = 0; i < 20; i++) {
        final id = repository.getNewId();
        await cache.store({'id': '$id', 'value': id * 2});
      }

      expect(repository.getCurrent(), equals(120));
      expect(cache.numberOfElements(), equals(20));

      for (var i = 0; i < 20; i++) {
        final cached = await cache.retrieve('${100 + i}');
        expect(cached, isNotNull);
        expect(cached!['value'], equals((100 + i) * 2));
      }
    });

    test('should handle cache reset after ID generation', () async {
      for (var i = 0; i < 30; i++) {
        final id = repository.getNewId();
        await cache.store({'id': '$id', 'batch': 'first'});
      }

      await cache.clear();
      expect(cache.numberOfElements(), equals(0));

      expect(repository.getNewId(), equals(30));
      await cache.store({'id': '30', 'batch': 'second'});
      expect(cache.numberOfElements(), equals(1));
    });

    test('should verify data consistency after multiple resets', () async {
      for (var i = 0; i < 10; i++) {
        final id = repository.getNewId();
        await cache.store({'id': '$id', 'phase': 1});
      }

      repository.reset();

      for (var i = 0; i < 10; i++) {
        final id = repository.getNewId();
        await cache.store({'id': 'phase2-$i', 'value': id});
      }

      expect(cache.numberOfElements(), equals(20));
      expect(repository.getCurrent(), equals(10));
    });
  });
}
