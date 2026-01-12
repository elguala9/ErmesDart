import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/src/standard_interface/i_id_handler.dart';
import 'package:test/test.dart';

/// Test suite per verificare l'implementazione di IIdHandlerRepository
/// Testa la generazione di ID sequenziali, wrapping, reset e consistenza
void testIdHandlerRepository<T extends IIdHandlerRepository>(
  String name,
  T Function() create,
) {
  group('IdHandlerRepository Tests - $name', () {
    late T repository;

    setUp(() {
      repository = create();
    });

    test('should generate sequential IDs starting from 0', () {
      expect(repository.getNewId(), equals(0));
      expect(repository.getNewId(), equals(1));
      expect(repository.getNewId(), equals(2));
    });

    test('should maintain current counter correctly', () {
      repository.getNewId(); // 0
      repository.getNewId(); // 1
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

      // Verify all IDs are sequential
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
      repository.getNewId(); // 0
      repository.setCounter(50);
      expect(repository.getCurrent(), equals(50));
      expect(repository.getNewId(), equals(50));
      expect(repository.getNewId(), equals(51));
    });
  });
}

/// Test suite per verificare l'implementazione di IIdHandlerService
/// Testa la generazione di ID attraverso il service layer
void testIdHandlerService<T extends IIdHandlerService>(
  String name,
  T Function() create,
) {
  group('IdHandlerService Tests - $name', () {
    late T service;

    setUp(() {
      service = create();
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
}

/// Test suite per verificare consistenza di ID con caching
void testIdHandlerWithCaching(
  String name,
  IIdHandlerRepository Function() createRepository,
  IErmesCachingRepository<Map<String, dynamic>> Function() createCache,
) {
  group('IdHandlerRepository with Caching - $name', () {
    late IIdHandlerRepository repository;
    late IErmesCachingRepository<Map<String, dynamic>> cache;

    setUp(() {
      repository = createRepository();
      cache = createCache();
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

      // Verify IDs are unique and sequential
      expect(ids.toSet().length, equals(50)); // All unique
      for (var i = 0; i < 50; i++) {
        expect(ids[i], equals(i));
      }

      // Verify cached
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

      // Verify all cached data is retrievable
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

      // IDs should continue from where they left
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
