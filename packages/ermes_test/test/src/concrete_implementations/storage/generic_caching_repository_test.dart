import 'package:ermes_storage/ermes_storage.dart';
import 'package:test/test.dart';

void main() {
  group('GenericCachingRepository', () {
    group('<String, String>', () {
      late GenericCachingRepository<String, String> repo;

      setUp(() {
        repo = GenericCachingRepository<String, String>(5);
      });

      tearDown(() async {
        await repo.destroy();
      });

      test('stores and retrieves by string key', () async {
        await repo.store('key1', 'hello');
        expect(await repo.retrieve('key1'), equals('hello'));
      });

      test('returns null for unknown key', () async {
        expect(await repo.retrieve('missing'), isNull);
      });

      test('updates value for existing key', () async {
        await repo.store('k', 'v1');
        await repo.store('k', 'v2');
        expect(repo.numberOfElements(), equals(1));
        expect(await repo.retrieve('k'), equals('v2'));
      });

      test('FIFO eviction when full', () async {
        for (var i = 0; i < 5; i++) {
          await repo.store('k$i', 'val$i');
        }
        await repo.store('k5', 'val5'); // evicts k0
        expect(await repo.retrieve('k0'), isNull);
        expect(await repo.retrieve('k5'), equals('val5'));
        expect(repo.numberOfElements(), equals(5));
      });

      test('delete returns true when key existed', () async {
        await repo.store('x', 'data');
        expect(await repo.delete('x'), isTrue);
        expect(repo.numberOfElements(), equals(0));
      });

      test('delete returns false for unknown key', () async {
        expect(await repo.delete('nope'), isFalse);
      });

      test('listOfIds returns all stored keys', () async {
        await repo.store('a', '1');
        await repo.store('b', '2');
        await repo.store('c', '3');
        final ids = await repo.listOfIds();
        expect(ids.toSet(), equals({'a', 'b', 'c'}));
      });

      test('clear removes all entries', () async {
        await repo.store('a', '1');
        await repo.store('b', '2');
        await repo.clear();
        expect(repo.numberOfElements(), equals(0));
        expect(await repo.listOfIds(), isEmpty);
      });
    });

    group('<int, Map<String, dynamic>>', () {
      late GenericCachingRepository<int, Map<String, dynamic>> repo;

      setUp(() {
        repo = GenericCachingRepository<int, Map<String, dynamic>>(10);
      });

      tearDown(() async => repo.destroy());

      test('stores arbitrary map objects', () async {
        await repo.store(1, {'name': 'Alice', 'age': 30});
        final retrieved = await repo.retrieve(1);
        expect(retrieved?['name'], equals('Alice'));
        expect(retrieved?['age'], equals(30));
      });

      test('stores multiple maps with different int keys', () async {
        for (var i = 0; i < 5; i++) {
          await repo.store(i, {'index': i});
        }
        expect(repo.numberOfElements(), equals(5));
        expect((await repo.retrieve(3))?['index'], equals(3));
      });
    });

    group('<String, bool> — deduplication pattern', () {
      late GenericCachingRepository<String, bool> repo;

      setUp(() {
        repo = GenericCachingRepository<String, bool>(3);
      });

      tearDown(() async => repo.destroy());

      test('first occurrence: retrieve returns null (not duplicate)', () async {
        final hash = 'abc123';
        expect(await repo.retrieve(hash), isNull);
      });

      test('after store: retrieve returns non-null (is duplicate)', () async {
        const hash = 'abc123';
        await repo.store(hash, true);
        expect(await repo.retrieve(hash), isNotNull);
      });

      test('different hashes are independent', () async {
        await repo.store('hash1', true);
        expect(await repo.retrieve('hash1'), isNotNull);
        expect(await repo.retrieve('hash2'), isNull);
      });

      test('FIFO eviction allows old hashes to be seen again', () async {
        // Fill buffer with 3 hashes
        await repo.store('h0', true);
        await repo.store('h1', true);
        await repo.store('h2', true);

        // Add one more — h0 gets evicted
        await repo.store('h3', true);

        // h0 is no longer remembered — a re-arriving message would pass
        expect(await repo.retrieve('h0'), isNull);
        // h1, h2, h3 are still remembered
        expect(await repo.retrieve('h1'), isNotNull);
        expect(await repo.retrieve('h2'), isNotNull);
        expect(await repo.retrieve('h3'), isNotNull);
      });
    });

    group('<String, Object> — fully unconstrained value type', () {
      late GenericCachingRepository<String, Object> repo;

      setUp(() {
        repo = GenericCachingRepository<String, Object>();
      });

      tearDown(() async => repo.destroy());

      test('stores int, string, list, map all in same cache', () async {
        await repo.store('num', 42);
        await repo.store('str', 'hello');
        await repo.store('lst', [1, 2, 3]);
        await repo.store('map', {'a': 1});

        expect(await repo.retrieve('num'), equals(42));
        expect(await repo.retrieve('str'), equals('hello'));
        expect(await repo.retrieve('lst'), equals([1, 2, 3]));
        expect((await repo.retrieve('map') as Map)['a'], equals(1));
      });

      test('default maxBuffer is 1000', () {
        expect(repo.maxBuffer, equals(1000));
      });
    });
  });
}
