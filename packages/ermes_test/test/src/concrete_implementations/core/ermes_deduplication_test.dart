import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Tests for the ErmesDeduplicationCache typedef and the deduplication
/// logic applied in ErmesReadRepo._handleMessageArrayBuffer.
///
/// The deduplication pattern is:
///   if (await cache.retrieve(hash) != null) return; // duplicate, discard
///   await cache.store(hash, true);                  // mark as seen
void testErmesDeduplication() {
  group('ErmesDeduplicationCache', () {
    late ErmesDeduplicationCache cache;

    setUp(() {
      cache = GenericCachingRepository<String, bool>(5);
    });

    tearDown(() async => cache.destroy());

    group('typedef correctness', () {
      test('is IGenericCachingRepository<String, bool>', () {
        expect(cache, isA<IGenericCachingRepository<String, bool>>());
      });

      test('created from GenericCachingRepository satisfies typedef', () {
        // Assigning to ErmesDeduplicationCache must compile and work
        final ErmesDeduplicationCache typed =
            GenericCachingRepository<String, bool>(10);
        expect(typed, isNotNull);
      });
    });

    group('deduplication logic', () {
      test('new hash: retrieve returns null → message is NOT a duplicate',
          () async {
        const hash = 'deadbeef01';
        expect(await cache.retrieve(hash), isNull);
      });

      test('after marking seen: retrieve returns non-null → IS a duplicate',
          () async {
        const hash = 'deadbeef01';
        await cache.store(hash, true);
        expect(await cache.retrieve(hash), isNotNull);
      });

      test('same hash arriving twice is detected on second call', () async {
        const hash = 'cafebabe99';
        var processedCount = 0;

        Future<void> simulateArrival(String h) async {
          if (await cache.retrieve(h) != null)
            return; // duplicate
          await cache.store(h, true);
          processedCount++;
        }

        await simulateArrival(hash);
        await simulateArrival(hash); // duplicate — should not increment
        await simulateArrival(hash); // still duplicate

        expect(processedCount, equals(1));
      });

      test('different hashes are processed independently', () async {
        final hashes = ['h1', 'h2', 'h3'];
        var processedCount = 0;

        for (final h in hashes) {
          if (await cache.retrieve(h) != null)
            continue;
          await cache.store(h, true);
          processedCount++;
        }

        expect(processedCount, equals(3));
      });

      test('FIFO eviction: oldest hash forgotten after buffer full', () async {
        // buffer size = 5, fill it completely
        for (var i = 0; i < 5; i++) {
          await cache.store('hash$i', true);
        }

        // hash0 still remembered
        expect(await cache.retrieve('hash0'), isNotNull);

        // add one more → hash0 evicted
        await cache.store('hash5', true);
        expect(await cache.retrieve('hash0'), isNull);

        // hash1–hash5 still remembered
        for (var i = 1; i <= 5; i++) {
          expect(await cache.retrieve('hash$i'), isNotNull,
              reason: 'hash$i should still be in cache');
        }
      });

      test(
          'evicted hash re-processed as new message (not duplicate)', () async {
        const evictedHash = 'old_msg_hash';
        await cache.store(evictedHash, true);

        // Fill buffer beyond capacity to evict the old hash
        for (var i = 0; i < 5; i++) {
          await cache.store('newer_hash_$i', true);
        }

        // evictedHash should now be gone — same message would be re-accepted
        expect(await cache.retrieve(evictedHash), isNull);
      });
    });

    group('state inspection via cache methods', () {
      test('numberOfElements tracks how many hashes are remembered', () async {
        expect(cache.numberOfElements(), equals(0));
        await cache.store('h1', true);
        await cache.store('h2', true);
        expect(cache.numberOfElements(), equals(2));
      });

      test('listOfIds returns all remembered hashes', () async {
        await cache.store('hash_a', true);
        await cache.store('hash_b', true);
        final ids = await cache.listOfIds();
        expect(ids.toSet(), equals({'hash_a', 'hash_b'}));
      });

      test('clear resets deduplication window', () async {
        await cache.store('seen_before', true);
        await cache.clear();
        // After clear, same hash is no longer considered duplicate
        expect(await cache.retrieve('seen_before'), isNull);
      });
    });
  });
}

void main() => testErmesDeduplication();
