import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void main() {
  group('GenericCachingService', () {
    group('delegates to repository correctly', () {
      late GenericCachingRepository<String, String> repo;
      late GenericCachingService<String, String> service;

      setUp(() {
        repo = GenericCachingRepository<String, String>(5);
        service = GenericCachingService<String, String>(repo);
      });

      tearDown(() async => service.destroy());

      test('store and retrieve', () async {
        await service.store('k', 'v');
        expect(await service.retrieve('k'), equals('v'));
      });

      test('numberOfElements reflects repository state', () async {
        await service.store('a', '1');
        await service.store('b', '2');
        expect(service.numberOfElements(), equals(2));
        expect(service.numberOfElements(), equals(repo.numberOfElements()));
      });

      test('delete removes entry', () async {
        await service.store('x', 'data');
        expect(await service.delete('x'), isTrue);
        expect(await service.retrieve('x'), isNull);
      });

      test('listOfIds returns all keys', () async {
        await service.store('p', '1');
        await service.store('q', '2');
        final ids = await service.listOfIds();
        expect(ids.toSet(), equals({'p', 'q'}));
      });

      test('clear empties the cache', () async {
        await service.store('a', '1');
        await service.clear();
        expect(service.numberOfElements(), equals(0));
      });

      test('destroy clears all data', () async {
        await service.store('a', '1');
        await service.store('b', '2');
        await service.destroy();
        expect(service.numberOfElements(), equals(0));
      });
    });

    group('with custom repository', () {
      test('accepts IGenericCachingRepository interface', () {
        final IGenericCachingRepository<int, double> customRepo =
            GenericCachingRepository<int, double>(20);
        final svc = GenericCachingService<int, double>(customRepo);
        expect(svc, isA<IGenericCachingService<int, double>>());
      });

      test('multiple service instances share independent repositories',
          () async {
        final repo1 = GenericCachingRepository<String, int>(10);
        final repo2 = GenericCachingRepository<String, int>(10);
        final svc1 = GenericCachingService<String, int>(repo1);
        final svc2 = GenericCachingService<String, int>(repo2);

        await svc1.store('key', 1);
        expect(await svc1.retrieve('key'), equals(1));
        expect(await svc2.retrieve('key'), isNull);

        await repo1.destroy();
        await repo2.destroy();
      });
    });

    group('edge cases and error handling', () {
      test('retrieve returns null for a key that was never stored', () async {
        final repo = GenericCachingRepository<String, String>(5);
        final svc = GenericCachingService<String, String>(repo);
        expect(await svc.retrieve('missing'), isNull);
        await svc.destroy();
      });

      test('delete returns false for a key that was never stored', () async {
        final repo = GenericCachingRepository<String, String>(5);
        final svc = GenericCachingService<String, String>(repo);
        expect(await svc.delete('missing'), isFalse);
        await svc.destroy();
      });

      test('listOfIds returns an empty list for a fresh cache', () async {
        final repo = GenericCachingRepository<String, String>(5);
        final svc = GenericCachingService<String, String>(repo);
        expect(await svc.listOfIds(), isEmpty);
        await svc.destroy();
      });

      test('numberOfElements is 0 for a fresh cache', () {
        final repo = GenericCachingRepository<String, String>(5);
        final svc = GenericCachingService<String, String>(repo);
        expect(svc.numberOfElements(), equals(0));
      });

      test('clear is idempotent when called repeatedly on an empty cache',
          () async {
        final repo = GenericCachingRepository<String, String>(5);
        final svc = GenericCachingService<String, String>(repo);
        await svc.clear();
        await svc.clear();
        expect(svc.numberOfElements(), equals(0));
      });

      test('destroy is idempotent when called repeatedly', () async {
        final repo = GenericCachingRepository<String, String>(5);
        final svc = GenericCachingService<String, String>(repo);
        await svc.store('a', '1');
        await svc.destroy();
        await svc.destroy();
        await svc.destroy();
        expect(svc.numberOfElements(), equals(0));
      });

      test('default maxBuffer (no argument) works for basic operations',
          () async {
        final repo = GenericCachingRepository<String, String>();
        expect(repo.maxBuffer, equals(1000));
        final svc = GenericCachingService<String, String>(repo);
        await svc.store('a', '1');
        expect(await svc.retrieve('a'), equals('1'));
        await svc.destroy();
      });

      test(
          'maxBuffer=1 evicts the oldest entry once a second key is stored',
          () async {
        final repo = GenericCachingRepository<String, String>(1);
        final svc = GenericCachingService<String, String>(repo);

        await svc.store('first', '1');
        await svc.store('second', '2');

        expect(svc.numberOfElements(), equals(1));
        expect(await svc.retrieve('first'), isNull);
        expect(await svc.retrieve('second'), equals('2'));
        await svc.destroy();
      });

      test('maxBuffer=0 evicts the entry immediately after insertion',
          () async {
        final repo = GenericCachingRepository<String, String>(0);
        final svc = GenericCachingService<String, String>(repo);

        await svc.store('only', '1');

        expect(svc.numberOfElements(), equals(0));
        expect(await svc.retrieve('only'), isNull);
        await svc.destroy();
      });

      test('re-storing an existing key refreshes its position and protects '
          'it from eviction ahead of older untouched keys', () async {
        final repo = GenericCachingRepository<String, String>(2);
        final svc = GenericCachingService<String, String>(repo);

        await svc.store('a', '1');
        await svc.store('b', '2');
        // Re-store 'a': it becomes the most recently inserted entry again.
        await svc.store('a', '1-updated');
        // Adding a third distinct key should now evict 'b', not 'a', since
        // 'a' was moved to the back of insertion order by the re-store.
        await svc.store('c', '3');

        expect(await svc.retrieve('a'), equals('1-updated'));
        expect(await svc.retrieve('b'), isNull);
        expect(await svc.retrieve('c'), equals('3'));
        await svc.destroy();
      });

      test('concurrent store calls on distinct keys all complete correctly',
          () async {
        final repo = GenericCachingRepository<String, int>(50);
        final svc = GenericCachingService<String, int>(repo);

        await Future.wait([
          for (var i = 0; i < 20; i++) svc.store('key$i', i),
        ]);

        expect(svc.numberOfElements(), equals(20));
        for (var i = 0; i < 20; i++) {
          expect(await svc.retrieve('key$i'), equals(i));
        }
        await svc.destroy();
      });
    });
  });
}
